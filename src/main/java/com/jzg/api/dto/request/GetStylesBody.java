package com.jzg.api.dto.request;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class GetStylesBody {
    private long modelId;
    private Long year;
    private Integer vehicleClassification;
    private Integer produceStatus;
    private Integer isEstimate;
    private Integer includeElectrombile;
}
