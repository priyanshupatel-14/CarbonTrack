package com.carbontrack.backend.points;

import com.carbontrack.backend.user.User;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.List;
import java.util.UUID;

public interface PointTransactionRepository extends JpaRepository<PointTransaction, UUID> {
    List<PointTransaction> findByUserOrderByCreatedAtDesc(User user);

    @Query("SELECT COALESCE(SUM(pt.points), 0) FROM PointTransaction pt WHERE pt.user = :user")
    int calculateBalanceByUser(@Param("user") User user);
}
