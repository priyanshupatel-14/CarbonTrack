package com.carbontrack.backend.verification;

public interface VisionApiClient {
    String getProviderName();
    VisionAnalysisResponse analyze(byte[] imageBytes, String mimeType, String prompt) throws Exception;
}
