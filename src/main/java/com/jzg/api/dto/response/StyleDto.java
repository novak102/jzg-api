package com.jzg.api.dto.response;

import com.alibaba.fastjson.annotation.JSONField;
import lombok.Data;

@Data
public class StyleDto {
    @JSONField(name = "styleId")
    private String styleId;

    @JSONField(name = "styleName")
    private String styleName;

    @JSONField(name = "styleFullName")
    private String styleFullName;

    @JSONField(name = "styleYear")
    private String styleYear;

    @JSONField(name = "msrp")
    private String msrp;

    @JSONField(name = "nextYear")
    private String nextYear;

    @JSONField(name = "displacement")
    private String displacement;

    @JSONField(name = "gearBox")
    private String gearBox;
}
