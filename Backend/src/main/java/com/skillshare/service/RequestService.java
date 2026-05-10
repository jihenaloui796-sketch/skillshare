package com.skillshare.service;

import com.skillshare.dto.request.RequestCreateRequest;
import com.skillshare.dto.request.RequestResponse;
import com.skillshare.dto.request.RequestUpdateRequest;
import com.skillshare.exception.BadRequestException;
import com.skillshare.exception.ResourceNotFoundException;
import com.skillshare.model.Skill;
import com.skillshare.model.SkillRequest;
import com.skillshare.model.RequestStatus;
import com.skillshare.model.Session;
import com.skillshare.model.User;
import com.skillshare.repository.SkillRepository;
import com.skillshare.repository.SkillRequestRepository;
import com.skillshare.repository.SessionRepository;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class RequestService {

    private final SkillRequestRepository requestRepository;
    private final SkillRepository skillRepository;
    private final SessionRepository sessionRepository;
    private final UserService userService;
    private final PushNotificationService pushNotificationService;

    public RequestService(SkillRequestRepository requestRepository,
                          SkillRepository skillRepository,
                          SessionRepository sessionRepository,
                          UserService userService,
                          PushNotificationService pushNotificationService) {
        this.requestRepository = requestRepository;
        this.skillRepository = skillRepository;
        this.sessionRepository = sessionRepository;
        this.userService = userService;
        this.pushNotificationService = pushNotificationService;
    }

    @Transactional
    public RequestResponse create(RequestCreateRequest request) {
        User current = userService.getCurrentUserOrThrow();
        Skill skill = skillRepository.findById(request.getSkillId())
                .orElseThrow(() -> new ResourceNotFoundException("Skill not found"));

        if (skill.getOwner().getId().equals(current.getId())) {
            throw new BadRequestException("You cannot request your own skill");
        }

        SkillRequest sr = SkillRequest.builder()
                .requester(current)
                .skill(skill)
                .message(request.getMessage())
                .build();

        SkillRequest saved = requestRepository.save(sr);

        if (skill.getOwner() != null && skill.getOwner().getFcmToken() != null) {
            pushNotificationService.sendToToken(
                    skill.getOwner().getFcmToken(),
                    "Nouvelle demande",
                    current.getFullName() + " a demandé votre compétence: " + skill.getName(),
                    java.util.Map.of(
                            "type", "request_created",
                            "requestId", String.valueOf(saved.getId()),
                            "skillId", String.valueOf(skill.getId())
                    )
            );
        }

        return toResponse(saved);
    }

    @Transactional(readOnly = true)
    public Page<RequestResponse> listMine(Pageable pageable) {
        User current = userService.getCurrentUserOrThrow();
        return requestRepository.findByRequesterId(current.getId(), pageable).map(RequestService::toResponse);
    }

    @Transactional(readOnly = true)
    public Page<RequestResponse> listIncoming(Pageable pageable) {
        User current = userService.getCurrentUserOrThrow();
        return requestRepository.findBySkill_Owner_Id(current.getId(), pageable).map(RequestService::toResponse);
    }

    @Transactional
    public RequestResponse update(Long id, RequestUpdateRequest request) {
        User current = userService.getCurrentUserOrThrow();
        SkillRequest sr = requestRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Request not found"));

        boolean isRequester = sr.getRequester().getId().equals(current.getId());
        boolean isOwner = sr.getSkill() != null && sr.getSkill().getOwner() != null
                && sr.getSkill().getOwner().getId().equals(current.getId());

        if (!isRequester && !isOwner) {
            throw new BadRequestException("Not allowed to update this request");
        }

        RequestStatus previousStatus = sr.getStatus();

        if (isRequester) {
            if (request.getMessage() != null) {
                sr.setMessage(request.getMessage());
            }
            if (request.getStatus() == RequestStatus.CANCELLED) {
                sr.setStatus(RequestStatus.CANCELLED);
            }
        }

        if (isOwner) {
            if (previousStatus == RequestStatus.OPEN) {
                if (request.getStatus() == RequestStatus.ACCEPTED) {
                    sr.setStatus(RequestStatus.ACCEPTED);

                    sessionRepository.findByRequestId(sr.getId()).orElseGet(() ->
                            sessionRepository.save(Session.builder()
                                    .request(sr)
                                    .skill(sr.getSkill())
                                    .owner(sr.getSkill().getOwner())
                                    .requester(sr.getRequester())
                                    .build())
                    );
                } else if (request.getStatus() == RequestStatus.CANCELLED) {
                    sr.setStatus(RequestStatus.CANCELLED);
                } else {
                    throw new BadRequestException("Owner can only ACCEPT or CANCEL an OPEN request");
                }
            } else if (previousStatus == RequestStatus.ACCEPTED) {
                if (request.getStatus() == RequestStatus.COMPLETED) {
                    sr.setStatus(RequestStatus.COMPLETED);

                    if (sr.getSkill() != null && sr.getSkill().getOwner() != null) {
                        userService.addPoints(sr.getSkill().getOwner(), 10);
                    }
                    if (sr.getRequester() != null) {
                        userService.addPoints(sr.getRequester(), 10);
                    }
                } else {
                    throw new BadRequestException("Only ACCEPTED requests can be completed");
                }
            } else {
                throw new BadRequestException("Request cannot be updated in its current status");
            }
        }

        SkillRequest saved = requestRepository.save(sr);

        RequestStatus newStatus = saved.getStatus();
        if (previousStatus != newStatus && isOwner && saved.getRequester() != null) {
            User requester = saved.getRequester();
            String token = requester.getFcmToken();
            if (token != null && !token.isBlank()) {
                if (newStatus == RequestStatus.ACCEPTED) {
                    pushNotificationService.sendToToken(
                            token,
                            "Demande acceptée",
                            "Votre demande pour \"" + (saved.getSkill() != null ? saved.getSkill().getName() : "la compétence") + "\" a été acceptée.",
                            java.util.Map.of(
                                    "type", "request_accepted",
                                    "requestId", String.valueOf(saved.getId())
                            )
                    );
                } else if (newStatus == RequestStatus.CANCELLED && previousStatus == RequestStatus.OPEN) {
                    pushNotificationService.sendToToken(
                            token,
                            "Demande refusée",
                            "Votre demande pour \"" + (saved.getSkill() != null ? saved.getSkill().getName() : "la compétence") + "\" a été refusée.",
                            java.util.Map.of(
                                    "type", "request_refused",
                                    "requestId", String.valueOf(saved.getId())
                            )
                    );
                } else if (newStatus == RequestStatus.COMPLETED) {
                    pushNotificationService.sendToToken(
                            token,
                            "Session terminée",
                            "La session pour \"" + (saved.getSkill() != null ? saved.getSkill().getName() : "la compétence") + "\" est terminée.",
                            java.util.Map.of(
                                    "type", "request_completed",
                                    "requestId", String.valueOf(saved.getId())
                            )
                    );
                }
            }
        }

        return toResponse(saved);
    }

    static RequestResponse toResponse(SkillRequest r) {
        return RequestResponse.builder()
                .id(r.getId())
                .requesterId(r.getRequester() != null ? r.getRequester().getId() : null)
                .requesterFullName(r.getRequester() != null ? r.getRequester().getFullName() : null)
                .skillId(r.getSkill() != null ? r.getSkill().getId() : null)
                .skillName(r.getSkill() != null ? r.getSkill().getName() : null)
                .skillOwnerId(r.getSkill() != null && r.getSkill().getOwner() != null ? r.getSkill().getOwner().getId() : null)
                .status(r.getStatus())
                .message(r.getMessage())
                .createdAt(r.getCreatedAt())
                .build();
    }
}
