package com.skillshare.service;

import com.skillshare.dto.session.SessionResponse;
import com.skillshare.exception.BadRequestException;
import com.skillshare.exception.ResourceNotFoundException;
import com.skillshare.model.Session;
import com.skillshare.model.User;
import com.skillshare.repository.SessionRepository;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class SessionService {

    private final SessionRepository sessionRepository;
    private final UserService userService;

    public SessionService(SessionRepository sessionRepository, UserService userService) {
        this.sessionRepository = sessionRepository;
        this.userService = userService;
    }

    @Transactional(readOnly = true)
    public Page<SessionResponse> listMine(Pageable pageable) {
        User current = userService.getCurrentUserOrThrow();
        return sessionRepository.findByOwner_IdOrRequester_Id(current.getId(), current.getId(), pageable)
                .map(SessionService::toResponse);
    }

    @Transactional(readOnly = true)
    public SessionResponse getMine(Long id) {
        User current = userService.getCurrentUserOrThrow();
        Session session = sessionRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Session not found"));

        boolean isParticipant = session.getOwner().getId().equals(current.getId())
                || session.getRequester().getId().equals(current.getId());
        if (!isParticipant) {
            throw new BadRequestException("Not allowed to view this session");
        }

        return toResponse(session);
    }

    static SessionResponse toResponse(Session s) {
        return SessionResponse.builder()
                .id(s.getId())
                .requestId(s.getRequest() != null ? s.getRequest().getId() : null)
                .skillId(s.getSkill() != null ? s.getSkill().getId() : null)
                .skillName(s.getSkill() != null ? s.getSkill().getName() : null)
                .ownerId(s.getOwner() != null ? s.getOwner().getId() : null)
                .requesterId(s.getRequester() != null ? s.getRequester().getId() : null)
                .createdAt(s.getCreatedAt())
                .build();
    }
}
