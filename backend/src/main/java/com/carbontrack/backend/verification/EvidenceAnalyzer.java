package com.carbontrack.backend.verification;

import com.carbontrack.backend.action.SustainableAction;
import java.util.List;

public interface EvidenceAnalyzer {
    AnalysisResult analyze(Evidence evidence, SustainableAction action);

    record AnalysisResult(
        boolean isValid,
        double confidence,
        String detectedContent,
        String explanation,
        String providerMetadata,
        List<String> detectedElements,
        boolean isSuspicious,
        String provider,
        String model,
        String fraudRisk,
        boolean possibleAiGenerated,
        boolean possibleManipulation,
        boolean possibleRecapture,
        List<String> fraudIndicators
    ) {
        // Backwards-compatible constructor for 9-argument callers
        public AnalysisResult(
            boolean isValid,
            double confidence,
            String detectedContent,
            String explanation,
            String providerMetadata,
            List<String> detectedElements,
            boolean isSuspicious,
            String provider,
            String model
        ) {
            this(
                isValid,
                confidence,
                detectedContent,
                explanation,
                providerMetadata,
                detectedElements,
                isSuspicious,
                provider,
                model,
                isSuspicious ? "HIGH" : "LOW",
                isSuspicious,
                isSuspicious,
                false,
                isSuspicious ? List.of("Suspicious visual indicators") : List.of()
            );
        }

        // Backwards-compatible constructor for 5-argument callers
        public AnalysisResult(boolean isValid, double confidence, String detectedContent, String explanation, String providerMetadata) {
            this(isValid, confidence, detectedContent, explanation, providerMetadata, List.of(), false, providerMetadata, "default");
        }
    }
}
