package com.carbontrack.backend.action;

import com.carbontrack.backend.user.User;
import org.springframework.data.jpa.repository.JpaRepository;
import java.util.List;
import java.util.UUID;

public interface ActionSubmissionRepository extends JpaRepository<ActionSubmission, UUID> {
    List<ActionSubmission> findByUser(User user);
    List<ActionSubmission> findByStatus(SubmissionStatus status);
}
