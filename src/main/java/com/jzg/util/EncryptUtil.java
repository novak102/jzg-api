package com.jzg.util;

// 导入 java.util.Base64 替换 sun.misc.*
import java.util.Base64;
import javax.crypto.*;
import javax.crypto.spec.DESedeKeySpec;
import java.io.UnsupportedEncodingException;
import java.security.InvalidKeyException;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.security.SecureRandom;
import java.security.spec.InvalidKeySpecException;

/**
 * 加密工具类 (整合自您提供的 EncryptUtil 和 SignUtil)
 */
public class EncryptUtil {

    /**
     * MD5值计算
     * (来自您的原始文件)
     */
    public final static byte[] MD5(String str) {
        try {
            byte[] res = str.getBytes("UTF-8");
            MessageDigest mdTemp = MessageDigest.getInstance("MD5".toUpperCase());
            mdTemp.update(res);
            return mdTemp.digest();
        } catch (Exception e) {
            return null;
        }
    }

    /**
     * 3DES加密
     * (来自您的原始文件)
     */
    public static byte[] DES3Encrypt(String key, String str) throws NoSuchAlgorithmException,
            NoSuchPaddingException, InvalidKeyException, UnsupportedEncodingException,
            InvalidKeySpecException, IllegalBlockSizeException, BadPaddingException {
        byte[] newkey = key.getBytes();
        SecureRandom sr = new SecureRandom();
        DESedeKeySpec dks = new DESedeKeySpec(newkey);
        SecretKeyFactory keyFactory = SecretKeyFactory.getInstance("DESede");
        SecretKey securekey = keyFactory.generateSecret(dks);
        Cipher cipher = Cipher.getInstance("DESede/ECB/PKCS5Padding");
        cipher.init(Cipher.ENCRYPT_MODE, securekey, sr);
        return cipher.doFinal(str.getBytes("utf-8"));
    }

    /**
     * 3DES解密
     * (来自您的原始文件)
     */
    public static String DES3Decrypt(byte[] edata, String key) {
        String data = "";
        try {
            if (edata != null) {
                byte[] newkey = key.getBytes();
                DESedeKeySpec dks = new DESedeKeySpec(newkey);
                SecretKeyFactory keyFactory = SecretKeyFactory.getInstance("DESede");
                SecretKey securekey = keyFactory.generateSecret(dks);
                Cipher cipher = Cipher.getInstance("DESede/ECB/PKCS5Padding");
                cipher.init(Cipher.DECRYPT_MODE, securekey, new SecureRandom());
                byte[] bb = cipher.doFinal(edata);
                data = new String(bb, "UTF-8");
            }
        } catch (Exception e) {
            e.printStackTrace();
        }
        return data;
    }

    /**
     * BASE64加密 (已替换为 java.util.Base64)
     */
    public static String BASE64Encrypt(byte[] key) {
        String edata = Base64.getEncoder().encodeToString(key).trim();
        return edata.replaceAll("\r|\n", "");
    }

    /**
     * BASE64解密 (已替换为 java.util.Base64)
     */
    public static byte[] BASE64Decrypt(String data) {
        if (data == null) {
            return null;
        }
        try {
            return Base64.getDecoder().decode(data);
        } catch (Exception e) {
            e.printStackTrace();
        }
        return null;
    }

    // --- 以下方法从 SignUtil.java 移入 ---

    /**
     * 加密签名 (来自您的 SignUtil.java)
     * 签名规则: ToBase64 (Md5 (sequenceId + partner Id + operate + body + key))
     */
    public static String getSignature(String operate, String partnerId, String key, String encryptBody, String sequenceId) {
        StringBuffer str = new StringBuffer();
        str.append(sequenceId);
        str.append(partnerId);
        str.append(operate);
        str.append(encryptBody);
        str.append(key);
        return BASE64Encrypt(MD5(str.toString()));
    }

    /**
     * 加密请求报文体 (来自您的 EncryptUtil.java)
     * 规则: ToBase64(3DES(Body明文))
     */
    public static String getBodyEncryption(String key, String body) {
        try {
            return BASE64Encrypt(DES3Encrypt(key, body));
        } catch (Exception e) {
            e.printStackTrace();
        }
        return null;
    }

    /**
     * 解密返回的报文体body (来自您的 SignUtil.java)
     * 规则: Decrypt3DES(FromBase64(Body密文))
     */
    public static String getDecodeBodyMessage(String body, String key) {
        return DES3Decrypt(BASE64Decrypt(body), key);
    }
}
