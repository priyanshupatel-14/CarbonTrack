package com.carbontrack.backend.action;

import org.springframework.data.jpa.repository.JpaRepository;
import java.util.List;
import java.util.UUID;

public interface SustainableActionRepository extends JpaRepository<SustainableAction, UUID> {
    List<SustainableAction> findByStatus(ActionStatus status);
}
