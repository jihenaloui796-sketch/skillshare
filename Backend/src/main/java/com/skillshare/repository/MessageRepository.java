package com.skillshare.repository;

import com.skillshare.model.Message;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.List;

public interface MessageRepository extends JpaRepository<Message, Long> {

    @Query("select m from Message m where (m.sender.id = :a and m.receiver.id = :b) or (m.sender.id = :b and m.receiver.id = :a) order by m.createdAt asc")
    List<Message> findConversation(@Param("a") Long a, @Param("b") Long b);

    @Query("select m from Message m where m.receiver.id = :receiverId and m.sender.id = :senderId and m.read = false")
    List<Message> findUnreadFromSender(@Param("receiverId") Long receiverId, @Param("senderId") Long senderId);

    @Modifying
    @Query("update Message m set m.read = true where m.receiver.id = :receiverId and m.sender.id = :senderId and m.read = false")
    int markRead(@Param("receiverId") Long receiverId, @Param("senderId") Long senderId);

    @Query("select m from Message m where m.sender.id = :userId or m.receiver.id = :userId")
    Page<Message> findAllForUser(@Param("userId") Long userId, Pageable pageable);
}
