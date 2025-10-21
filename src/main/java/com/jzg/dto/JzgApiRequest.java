package com.jzg.dto;

import lombok.Data;

/**
 * JZG API 协议的通用请求包装类
 * (对应文档 3.1 请求消息)
 */
@Data
public class JzgApiRequest {
    /**
     * 请求接口时的时间
     * 格式: "yyyy-MM-dd HH:mm:ss"
     */
    private String sequenceId;

    /**
     * 合作伙伴id, 由精真估分配
     */
    private String partnerId;

    /**
     * (新接口暂时没用,为兼容老接口而保留的)
     */
    private String operate;

    /**
     * 消息签名
     * 签名规则: ToBase64 (Md5 (sequenceId + partner Id + operate + body + key))
     */
    private String sign;

    /**
     * 加密后的业务请求体 (JSON 字符串)
     * 加密规则: ToBase64(3DES(Body明文))
     */
    private String body;
}
