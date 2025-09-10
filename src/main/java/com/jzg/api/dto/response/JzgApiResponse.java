package com.jzg.api.dto.response;

import lombok.Data;

/**
 * 精真估 API 的通用响应结构。
 * 这里的 body 字段仍然是加密的字符串。
 */
@Data
public class JzgApiResponse {
    private int errorCode;
    private String errorMessage;
    private long timeStamp;
    private String sign;
    private String body; // 加密的消息体
    private String sequenceId;
}
