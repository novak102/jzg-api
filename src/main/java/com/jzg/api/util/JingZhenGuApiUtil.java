package com.jzg.api.util;

import javax.crypto.Cipher;
import javax.crypto.SecretKey;
import javax.crypto.SecretKeyFactory;
import javax.crypto.spec.DESedeKeySpec;
import java.io.UnsupportedEncodingException;
import java.net.URLDecoder;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.security.SecureRandom;
import java.util.Base64;

public class JingZhenGuApiUtil {

    public static String encrypt3DESToBase64(String plainText, String key) throws Exception {
        byte[] newkey = key.getBytes();
        SecureRandom sr = new SecureRandom();
        DESedeKeySpec dks = new DESedeKeySpec(newkey);
        SecretKeyFactory keyFactory = SecretKeyFactory.getInstance("DESede");
        SecretKey securekey = keyFactory.generateSecret(dks);
        Cipher cipher = Cipher.getInstance("DESede/ECB/PKCS5Padding");
        cipher.init(Cipher.ENCRYPT_MODE, securekey, sr);
        byte[] bt = cipher.doFinal(plainText.getBytes("utf-8"));
        return Base64.getEncoder().encodeToString(bt);
    }

    public static String decrypt3DESFromBase64(String base64CipherText, String key) throws Exception {
        byte[] edata = Base64.getDecoder().decode(base64CipherText);
        String data = "";
        if (edata != null) {
            byte[] newkey = key.getBytes();
            DESedeKeySpec dks = new DESedeKeySpec(newkey);
            SecretKeyFactory keyFactory = SecretKeyFactory.getInstance("DESede");
            SecretKey securekey = keyFactory.generateSecret(dks);
            Cipher cipher = Cipher.getInstance("DESede/ECB/PKCS5Padding");
            cipher.init(Cipher.DECRYPT_MODE, securekey, new SecureRandom());

            String newData = new String(edata);
            if (!newData.endsWith("=")) {
                data = URLDecoder.decode(newData, "utf-8");
            }

            byte[] bb = cipher.doFinal(edata);
            data = new String(bb, "utf-8");
        }
        return data;
    }

    public static String generateSign(String sequenceId, String partnerId, String operate, String encryptedBody, String key) throws UnsupportedEncodingException, NoSuchAlgorithmException {
        String stringToSign = sequenceId + partnerId + operate + encryptedBody + key;
        MessageDigest md = MessageDigest.getInstance("MD5");
        byte[] md5Bytes = md.digest(stringToSign.getBytes("UTF-8"));
        return Base64.getEncoder().encodeToString(md5Bytes);
    }
}
