package com.jzg.api.service;

import com.jzg.api.dto.response.StyleDto;
import java.util.List;

public interface StyleService {
    List<StyleDto> getStylesByModelId(long modelId) throws Exception;
}
