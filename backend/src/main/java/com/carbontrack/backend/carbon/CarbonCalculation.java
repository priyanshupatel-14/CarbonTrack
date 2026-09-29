package com.carbontrack.backend.carbon;

import jakarta.persistence.*;
import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.UUID;

@Entity
@Table(name = "carbon_calculations")
public class CarbonCalculation {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @OneToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "activity_id", nullable = false, unique = true)
    private CarbonActivity carbonActivity;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "emission_factor_id")
    private EmissionFactor emissionFactor;

    @Column(nullable = false, precision = 19, scale = 6)
    private BigDecimal factorValueUsed;

    @Column(nullable = false)
    private int factorVersion;

    @Column(nullable = false, precision = 19, scale = 4)
    private BigDecimal co2e;

    @Column(nullable = false, updatable = false)
    private LocalDateTime calculationTimestamp;

    @PrePersist
    protected void onCreate() {
        calculationTimestamp = LocalDateTime.now();
    }

    // Getters and Setters
    public UUID getId() { return id; }
    public void setId(UUID id) { this.id = id; }
    public CarbonActivity getCarbonActivity() { return carbonActivity; }
    public void setCarbonActivity(CarbonActivity carbonActivity) { this.carbonActivity = carbonActivity; }
    public EmissionFactor getEmissionFactor() { return emissionFactor; }
    public void setEmissionFactor(EmissionFactor emissionFactor) { this.emissionFactor = emissionFactor; }
    public BigDecimal getFactorValueUsed() { return factorValueUsed; }
    public void setFactorValueUsed(BigDecimal factorValueUsed) { this.factorValueUsed = factorValueUsed; }
    public int getFactorVersion() { return factorVersion; }
    public void setFactorVersion(int factorVersion) { this.factorVersion = factorVersion; }
    public BigDecimal getCo2e() { return co2e; }
    public void setCo2e(BigDecimal co2e) { this.co2e = co2e; }
    public LocalDateTime getCalculationTimestamp() { return calculationTimestamp; }
}
