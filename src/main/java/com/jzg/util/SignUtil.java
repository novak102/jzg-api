package com.jzg.util;

import com.alibaba.fastjson.JSON;
import com.alibaba.fastjson.JSONObject;

import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.HashMap;
import java.util.Map;

public class SignUtil {

    /**
     * 调用接口
     */
    public static String callJavaApi(String url, String partnerId, String key, JSONObject param) throws Exception {
        //加密Body
        String encrypt = EncryptUtil.getBodyEncryption(key, param.toJSONString());
        String sequenceId = LocalDateTime.now().format(DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm:ss"));
        String operate = "";
        //加密Sign
        JSONObject object = new JSONObject();
        object.put("sequenceId", sequenceId);
        object.put("partnerId", partnerId);
        object.put("operate", operate);
        object.put("body", encrypt);
        String sign = EncryptUtil.getSignature(operate, partnerId, key, encrypt, sequenceId);
        object.put("sign", sign);
        Map<String, Object> paramMap = new HashMap<>(1);
        paramMap.put("json", object.toJSONString());
        return HttpUtils.doPostURL(url, paramMap);
    }


    /**
     * 解密返回的报文体body
     *
     * @param body
     * @param key
     * @return
     */
    public static String getDecodeBodyMessage(String body, String key) {
        return EncryptUtil.DES3Decrypt(EncryptUtil.BASE64Decrypt(body), key);
    }


    /**
     * 测试
     *
     * @param args
     * @throws Exception
     */
    public static void main(String[] args) throws Exception {
        String partnerId = "1010";
        String key = "Bg3pyUZrU6skS89m0URfFvNJ";

//        server.port=8080
//        jzg.api.base-url=http://nvapi.sandbox.jingzhengu.com
//        jzg.api.partner-id=1010
//        jzg.api.secret-key=Bg3pyUZrU6skS89m0URfFvNJ
        GetMakeByAllRequest plainBodyRequest = GetMakeByAllRequest.builder()
                .vehicleClassification(1).produceStatus(1).isEstimate(0).includeElectrombile(1).build();

        JSONObject paramsJson = (JSONObject) JSON.toJSON(plainBodyRequest);
        String url = "http://nvapi.sandbox.jingzhengu.com/external/getMakeByAll";
        String result = callJavaApi(url, partnerId, key, paramsJson);
        if (result != null && !"".equals(result.trim())) {
            JSONObject parse = JSONObject.parseObject(result);
            String body = parse.get("body").toString();
            System.out.println("body===>"+getDecodeBodyMessage(body, key));
        }


    }

}
