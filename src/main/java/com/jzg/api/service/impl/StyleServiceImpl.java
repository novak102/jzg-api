package com.jzg.api.service.impl;

import com.jzg.api.dao.StyleDao;
import com.jzg.api.dto.response.StyleDto;
import com.jzg.api.service.StyleService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.util.List;

@Service
public class StyleServiceImpl implements StyleService {

    private final StyleDao styleDao;

    // 构造器注入 DAO
    @Autowired
    public StyleServiceImpl(StyleDao styleDao) {
        this.styleDao = styleDao;
    }

    @Override
    public List<StyleDto> getStylesByModelId(long modelId) throws Exception {
        // 可以在这里添加业务逻辑，比如缓存、数据过滤等
        return styleDao.selectStylesByModelId(modelId);
    }
}
