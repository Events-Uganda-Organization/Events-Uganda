package com.eventsuganda.otp.repository;

import com.eventsuganda.otp.model.MessageMedia;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.Collection;
import java.util.List;
import java.util.Optional;

@Repository
public interface MessageMediaRepository extends JpaRepository<MessageMedia, String> {

    interface MediaMeta {
        String getMessageId();
        String getId();
        String getMediaType();
        Long getDurationMs();
    }

    @Query("SELECT m.messageId AS messageId, m.id AS id, m.mediaType AS mediaType, m.durationMs AS durationMs " +
           "FROM MessageMedia m WHERE m.messageId IN :ids")
    List<MediaMeta> findMetaByMessageIdIn(@Param("ids") Collection<String> ids);

    Optional<MessageMedia> findByMessageId(String messageId);

    List<MessageMedia> findByMediaTypeOrderByCreatedAtAsc(String mediaType, Pageable pageable);

    @Modifying
    @Query("DELETE FROM MessageMedia m WHERE m.messageId IN :ids")
    int deleteByMessageIdIn(@Param("ids") Collection<String> ids);
}
