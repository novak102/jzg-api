package com.jzg.util;

import org.apache.http.HttpEntity;
import org.apache.http.HttpResponse;
import org.apache.http.HttpStatus;
import org.apache.http.NameValuePair;
import org.apache.http.client.config.RequestConfig;
import org.apache.http.client.entity.UrlEncodedFormEntity;
import org.apache.http.client.methods.CloseableHttpResponse;
import org.apache.http.client.methods.HttpGet;
import org.apache.http.client.methods.HttpPost;
import org.apache.http.conn.ssl.SSLConnectionSocketFactory;
import org.apache.http.conn.ssl.SSLContextBuilder;
import org.apache.http.conn.ssl.TrustStrategy;
import org.apache.http.conn.ssl.X509HostnameVerifier;
import org.apache.http.entity.StringEntity;
import org.apache.http.impl.client.CloseableHttpClient;
import org.apache.http.impl.client.HttpClients;
import org.apache.http.impl.conn.PoolingHttpClientConnectionManager;
import org.apache.http.message.BasicNameValuePair;
import org.apache.http.util.EntityUtils;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import javax.net.ssl.SSLContext;
import javax.net.ssl.SSLException;
import javax.net.ssl.SSLSession;
import javax.net.ssl.SSLSocket;
import java.io.IOException;
import java.io.UnsupportedEncodingException;
import java.net.URLEncoder;
import java.nio.charset.Charset;
import java.security.GeneralSecurityException;
import java.security.cert.CertificateException;
import java.security.cert.X509Certificate;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

/**
 * Created by JZG on 2018/1/11.
 */
public class HttpUtils {

    /**
     * HTTP请求URL与参数分隔符
     */
    public static final String HTTP_REQUEST_URL_SPLIT = "?";
    /**
     * 日志
     */
    private static Logger logger = LoggerFactory.getLogger(HttpUtils.class);

    /**
     * 连接池
     */
    private static PoolingHttpClientConnectionManager poolingHttpClientConnectionManager;
    /**
     * 请求配置
     */
    private static RequestConfig requestConfig;
    /**
     * 从连接池获取连接时间
     */
    private static final int CONNECTION_REQUEST_TIMEOUT = 2 * 1000;
    /**
     * 连接建立的超时时间
     */
    private static final int CONNECTION_TIMEOUT = 2 * 1000;
    /**
     * 响应超时时间，超过此时间不再读取响应；客户端从服务器读取数据的超时时间
     */
    private static final int SOCKET_TIMEOUT = 10 * 1000;
    /**
     * 连接池大小
     */
    private static final int MAX_TOTAL = 200;
    /**
     * 默认编码
     */
    private static final String DEFAULT_ENCODING = "UTF-8";

    private HttpUtils() {
    }

    static {
        // 设置连接池
        poolingHttpClientConnectionManager = new PoolingHttpClientConnectionManager();
        // 设置连接池大小
        poolingHttpClientConnectionManager.setMaxTotal(MAX_TOTAL);
        poolingHttpClientConnectionManager.setDefaultMaxPerRoute(poolingHttpClientConnectionManager.getMaxTotal());

        RequestConfig.Builder configBuilder = RequestConfig.custom();
        // 设置连接超时
        configBuilder.setConnectTimeout(CONNECTION_TIMEOUT);
        // 设置读取超时
        configBuilder.setSocketTimeout(SOCKET_TIMEOUT);
        // 设置从连接池获取连接实例的超时
        configBuilder.setConnectionRequestTimeout(CONNECTION_REQUEST_TIMEOUT);
        // 在提交请求之前 测试连接是否可用
        //configBuilder.setStaleConnectionCheckEnabled(true);
        requestConfig = configBuilder.build();
    }

    /**
     * 发送 GET 请求（HTTP），不带输入数据
     *
     * @param url the url
     * @return string
     */
    public static String doGet(String url) {
        return doGet(url, new HashMap<String, Object>());
    }

    /**
     * 发送 GET 请求（HTTP），不带输入数据
     *
     * @param url         请求URL
     * @param queryString 请求参数，例如t=1232&p=test
     * @return string
     */
    public static String doGet(String url, String queryString) {
        if (url == null || "".equals(url.trim())) {
            return "";
        }

        String newUrl = "";
        String newQueryString = "";
        if (url != null && url.endsWith(HTTP_REQUEST_URL_SPLIT)) {
            newUrl = url.substring(0, url.length() - 1);
            newUrl = newUrl.trim();
        }
        if (queryString != null && queryString.startsWith(HTTP_REQUEST_URL_SPLIT)) {
            newQueryString = queryString.substring(1);
            newQueryString = newQueryString.trim();
        }

        return doGet(String.format("%s?%s", newUrl, newQueryString));
    }

    /**
     * 发送 GET 请求（HTTP），K-V形式
     *
     * @param url    the url
     * @param params the params
     * @return string
     */
    public static String doGet(String url, Map<String, Object> params) {
        String result = null;

        url = buildGetRequestUrl(url, params);
        logger.debug(url);
        //System.out.println(url);

        //HttpClient httpclient = new DefaultHttpClient();
        CloseableHttpClient httpclient = HttpClients.createDefault();
        HttpResponse response = null;

        try {
            HttpGet httpGet = new HttpGet(url);
            response = httpclient.execute(httpGet);
            int statusCode = response.getStatusLine().getStatusCode();
            //System.out.println("执行状态码 : " + statusCode);
            HttpEntity entity = response.getEntity();
            result = EntityUtils.toString(entity, DEFAULT_ENCODING);
        } catch (IOException e) {
            logger.error(e.getMessage(), e);
        }
        if (response != null) {
            try {
                EntityUtils.consume(response.getEntity());
            } catch (IOException e) {
                logger.error(e.getMessage(), e);
            }
        }
        return result;
    }

    /**
     * 构建URL分隔符
     *
     * @param url    请求URL
     * @param params 请求参数
     * @return 拼接后的URL
     */
    private static String buildGetRequestUrl(String url, Map<String, Object> params) {
        StringBuffer sb = new StringBuffer();
        sb.append(url);
        int i = 0;

        for (Map.Entry<String, Object> entry : params.entrySet()) {
            //过滤空值
            String str = (String) entry.getValue();
            if (str == null || "".equals(str.trim())) {
                continue;
            }

            if (i == 0) {
                sb.append("?");
            } else {
                sb.append("&");
            }

            //对象转化为字符串 Http请求默认传输Object为String[]
            String val = getValue(entry.getValue());

            try {
                val = URLEncoder.encode(val, DEFAULT_ENCODING);
            } catch (UnsupportedEncodingException e) {
                //e.printStackTrace();
                logger.error(e.getMessage(), e);
            }

            sb.append(entry.getKey()).append("=").append(val);
            i++;
        }

        url = sb.toString();
        return url;
    }

    /**
     * 发送 POST 请求（HTTP），不带输入数据
     *
     * @param url the url
     * @return string
     */
    public static String doPost(String url) {
        return doPostURL(url, new HashMap<String, Object>());
    }

    /**
     * 发送 POST 请求（HTTP），K-V形式
     *
     * @param url    API接口URL
     * @param params 参数map
     * @return string
     */
    public static String doPostURL(String url, Map<String, Object> params) {
        return doPostURL(url, params, true);
    }

    public static String doPostURL(String url, Map<String, Object> params, boolean ignoreEmpty) {
        String result = null;

        CloseableHttpClient httpClient = HttpClients.createDefault();
        HttpPost httpPost = new HttpPost(url);
        CloseableHttpResponse response = null;

        try {
            httpPost.setConfig(requestConfig);
            List<NameValuePair> pairList = new ArrayList<>(params.size());
            for (Map.Entry<String, Object> entry : params.entrySet()) {
                //过滤空值
                String val;
                if (entry.getValue() == null || entry.getValue().equals("")) {
                    if (ignoreEmpty) {
                        continue;
                    }
                    val = "";
                } else {
                    val = getValue(entry.getValue());
                }

                NameValuePair pair = new BasicNameValuePair(entry.getKey(), val);
                pairList.add(pair);
            }
            httpPost.setEntity(new UrlEncodedFormEntity(pairList, Charset.forName(DEFAULT_ENCODING)));
            response = httpClient.execute(httpPost);
            HttpEntity entity = response.getEntity();
            result = EntityUtils.toString(entity, DEFAULT_ENCODING);
        } catch (IOException e) {
            logger.error(e.getMessage(), e);
        } finally {
            if (response != null) {
                try {
                    EntityUtils.consume(response.getEntity());
                } catch (IOException e) {
                    logger.error(e.getMessage(), e);
                }
            }
        }
        return result;
    }

    /**
     * 发送 POST 请求（HTTP），JSON形式
     *
     * @param url  the url
     * @param json json字符串
     * @return string
     */
    public static String doPost(String url, String json) {
        String result = null;

        CloseableHttpClient httpClient = HttpClients.createDefault();
        HttpPost httpPost = new HttpPost(url);
        CloseableHttpResponse response = null;

        try {
            httpPost.setConfig(requestConfig);
            StringEntity stringEntity = new StringEntity(json.toString(), DEFAULT_ENCODING); //解决中文乱码问题
            stringEntity.setContentEncoding(DEFAULT_ENCODING);
            stringEntity.setContentType("application/json");
            httpPost.setEntity(stringEntity);
            response = httpClient.execute(httpPost);
            HttpEntity entity = response.getEntity();
            result = EntityUtils.toString(entity, DEFAULT_ENCODING);
        } catch (IOException e) {
            logger.error(e.getMessage(), e);
        } finally {
            if (response != null) {
                try {
                    EntityUtils.consume(response.getEntity());
                } catch (IOException e) {
                    logger.error(e.getMessage(), e);
                }
            }
        }
        return result;
    }

    /**
     * 发送 SSL POST 请求（HTTPS），K-V形式
     *
     * @param url    API接口URL
     * @param params 参数map
     * @return string
     */
    public static String doPostSSL(String url, Map<String, Object> params) {
        String result = null;

        CloseableHttpClient httpClient = HttpClients.custom().setSSLSocketFactory(createSSLConnSocketFactory())
                .setConnectionManager(poolingHttpClientConnectionManager).setDefaultRequestConfig(requestConfig).build();
        HttpPost httpPost = new HttpPost(url);
        CloseableHttpResponse response = null;


        try {
            httpPost.setConfig(requestConfig);
            List<NameValuePair> pairList = new ArrayList<NameValuePair>(params.size());
            for (Map.Entry<String, Object> entry : params.entrySet()) {
                Object objVal = entry.getValue();
                String val = getValue(objVal);

                NameValuePair pair = new BasicNameValuePair(entry.getKey(), val);
                pairList.add(pair);
            }
            httpPost.setEntity(new UrlEncodedFormEntity(pairList, Charset.forName(DEFAULT_ENCODING)));
            response = httpClient.execute(httpPost);
            int statusCode = response.getStatusLine().getStatusCode();
            if (statusCode != HttpStatus.SC_OK) {
                return null;
            }
            HttpEntity entity = response.getEntity();
            if (entity == null) {
                return null;
            }
            result = EntityUtils.toString(entity, DEFAULT_ENCODING);
        } catch (Exception e) {
            logger.error(e.getMessage(), e);
        } finally {
            if (response != null) {
                try {
                    EntityUtils.consume(response.getEntity());
                } catch (IOException e) {
                    logger.error(e.getMessage(), e);
                }
            }
        }
        return result;
    }

    /**
     * 发送 SSL POST 请求（HTTPS），JSON形式
     *
     * @param url  API接口URL
     * @param json JSON对象
     * @return string
     */
    public static String doPostSSL(String url, Object json) {
        String result = null;

        CloseableHttpClient httpClient = HttpClients.custom().setSSLSocketFactory(createSSLConnSocketFactory())
                .setConnectionManager(poolingHttpClientConnectionManager).setDefaultRequestConfig(requestConfig).build();
        HttpPost httpPost = new HttpPost(url);
        CloseableHttpResponse response = null;


        try {
            httpPost.setConfig(requestConfig);
            StringEntity stringEntity = new StringEntity(json.toString(), DEFAULT_ENCODING); //解决中文乱码问题
            stringEntity.setContentEncoding(DEFAULT_ENCODING);
            stringEntity.setContentType("application/json");
            httpPost.setEntity(stringEntity);
            response = httpClient.execute(httpPost);
            int statusCode = response.getStatusLine().getStatusCode();
            if (statusCode != HttpStatus.SC_OK) {
                return null;
            }
            HttpEntity entity = response.getEntity();
            if (entity == null) {
                return null;
            }
            result = EntityUtils.toString(entity, DEFAULT_ENCODING);
        } catch (Exception e) {
            logger.error(e.getMessage(), e);
        } finally {
            if (response != null) {
                try {
                    EntityUtils.consume(response.getEntity());
                } catch (IOException e) {
                    logger.error(e.getMessage(), e);
                }
            }
        }
        return result;
    }


    /**
     * 创建SSL安全连接
     *
     * @return SSL连接工厂
     */
    private static SSLConnectionSocketFactory createSSLConnSocketFactory() {
        SSLConnectionSocketFactory sslsf = null;
        try {
            SSLContext sslContext = new SSLContextBuilder().loadTrustMaterial(null, new TrustStrategy() {

                public boolean isTrusted(X509Certificate[] chain, String authType) throws CertificateException {
                    return true;
                }
            }).build();
            sslsf = new SSLConnectionSocketFactory(sslContext, new X509HostnameVerifier() {

                @Override
                public boolean verify(String arg0, SSLSession arg1) {
                    return true;
                }

                @Override
                public void verify(String host, SSLSocket ssl) throws IOException {
                }

                @Override
                public void verify(String host, X509Certificate cert) throws SSLException {
                }

                @Override
                public void verify(String host, String[] cns, String[] subjectAlts) throws SSLException {
                }
            });
        } catch (GeneralSecurityException e) {
            logger.error(e.getMessage(), e);
        }
        return sslsf;
    }

    /**
     * 值类型转化
     *
     * @param objVal 参数值
     * @return 转化后参数值
     */
    private static String getValue(Object objVal) {
        String val = null;

        if (objVal instanceof String) {
            val = String.valueOf(objVal);
        } else if (objVal instanceof String[]) {
            val = ((String[]) objVal)[0];
        } else {
            throw new IllegalArgumentException("map type is eroor, please use Map<String,String> or Map<String, String[])");
        }
        return val;
    }
}
