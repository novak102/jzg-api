package com.jzg.api.dao;

import com.jzg.api.dto.response.StyleDto;
import java.util.List;

/**
 * 车型数据访问接口
 */
public interface StyleDao {
    /**
     * 根据车系ID查询车型列表
     * @param modelId 车系ID
     * @return 车型列表
     * @throws Exception 数据访问异常
     */
    List<StyleDto> selectStylesByModelId(long modelId) throws Exception;
}
