package com.carbontrack.backend.verification;

import com.carbontrack.backend.action.SustainableAction;
import org.springframework.stereotype.Service;

@Service
public class MockEvidenceAnalyzer implements EvidenceAnalyzer {

    @Override
    public AnalysisResult analyze(Evidence evidence, SustainableAction action) {
        // Deterministic mock logic based on file size or something simple
        // In real life this would call OpenAI/Gemini/AWS Rekognition
        
        if (evidence.getFileSize() != null && evidence.getFileSize() < 1000) {
            // Simulate a bad image
            return new AnalysisResult(
                false, 
                0.2, 
                "Blurry image, no clear subject", 
                "Image appears too small or blurry to be valid evidence.",
                "MockAnalyzer-v1"
            );
        }

        return new AnalysisResult(
            true, 
            0.95, 
            "Action related objects detected", 
            "The image clearly shows the requested sustainable action.",
            "MockAnalyzer-v1"
        );
    }
}
