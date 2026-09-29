package com.carbontrack.backend.verification;

import com.carbontrack.backend.action.SustainableAction;

public interface EvidenceAnalyzer {
    AnalysisResult analyze(Evidence evidence, SustainableAction action);

    record AnalysisResult(
        boolean isValid,
        double confidence,
        String detectedContent,
        String explanation,
        String providerMetadata
    ) {}
}
