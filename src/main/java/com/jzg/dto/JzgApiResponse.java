package com.jzg.dto;

import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import lombok.Data;

/**
 * JZG API 协议的通用响应包装类
 * (对应文档 3.2 成功返回消息)
 */
@Data
@JsonIgnoreProperties(ignoreUnknown = true) // 忽略 API 可能多返回的字段
public class JzgApiResponse {
    /**
     * 错误代码, 0 表示成功, 其他表示错误
     */
    private int errorCode;

    /**
     * 错误消息
     */
    private String errorMessage;

    /**
     * 服务器时间戳
     */
    private long timeStamp;

    /**
     * 消息签名
     */
    private String sign;

    /**
     * 加密后的业务响应体 (JSON 字符串)
     */
    private String body;
    
    /**
     * 请求接口时的时间 (原样返回)
     */
    private String sequenceId;
}
