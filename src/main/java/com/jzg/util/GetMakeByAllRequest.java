package com.jzg.util;
import lombok.Builder;
import lombok.Data;

@Data @Builder
public class GetMakeByAllRequest {
    private int vehicleClassification;
    private int produceStatus;
    private int isEstimate;
    private int includeElectrombile;
}
