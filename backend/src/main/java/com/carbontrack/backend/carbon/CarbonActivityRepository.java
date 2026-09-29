package com.carbontrack.backend.carbon;

import com.carbontrack.backend.user.User;
import org.springframework.data.jpa.repository.JpaRepository;

import java.time.LocalDate;
import java.util.List;
import java.util.UUID;

public interface CarbonActivityRepository extends JpaRepository<CarbonActivity, UUID> {
    List<CarbonActivity> findByUserOrderByActivityDateDescCreatedAtDesc(User user);
    
    List<CarbonActivity> findByUserAndActivityDateBetween(User user, LocalDate startDate, LocalDate endDate);
}
