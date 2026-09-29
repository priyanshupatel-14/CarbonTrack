package com.carbontrack.backend.carbon;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.time.LocalDateTime;
import java.util.Optional;
import java.util.UUID;

public interface EmissionFactorRepository extends JpaRepository<EmissionFactor, UUID> {
    
    @Query("SELECT e FROM EmissionFactor e WHERE e.category = :category AND e.activityType = :activityType " +
           "AND e.validFrom <= :date AND (e.validTo IS NULL OR e.validTo > :date) ORDER BY e.version DESC LIMIT 1")
    Optional<EmissionFactor> findValidFactor(
            @Param("category") Category category,
            @Param("activityType") ActivityType activityType,
            @Param("date") LocalDateTime date);
}
