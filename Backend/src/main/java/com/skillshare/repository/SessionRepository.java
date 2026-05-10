package com.skillshare.repository;

import com.skillshare.model.Session;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.Optional;

public interface SessionRepository extends JpaRepository<Session, Long> {

    Optional<Session> findByRequestId(Long requestId);

    Optional<Session> findByRequest_Id(Long requestId);

    Page<Session> findByOwnerIdOrRequesterId(Long ownerId, Long requesterId, Pageable pageable);

    Page<Session> findByOwner_IdOrRequester_Id(Long ownerId, Long requesterId, Pageable pageable);
}
