package com.carbontrack.backend.action;

import org.springframework.data.jpa.repository.JpaRepository;
import java.util.UUID;

public interface CampusZoneRepository extends JpaRepository<CampusZone, UUID> {
}
