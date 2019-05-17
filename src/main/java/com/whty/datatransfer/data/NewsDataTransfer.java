package com.whty.datatransfer.data;


import cn.hutool.core.io.file.FileReader;
import com.alibaba.fastjson.JSON;
import com.alibaba.fastjson.JSONArray;
import com.alibaba.fastjson.JSONObject;
import org.springframework.http.HttpEntity;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpMethod;
import org.springframework.http.MediaType;
import org.springframework.web.client.RestTemplate;

import java.text.ParseException;
import java.text.SimpleDateFormat;
import java.util.Date;

import org.apache.commons.logging.Log;
import org.apache.commons.logging.LogFactory;

/**
 * 校内通知数据迁移
 */
public class NewsDataTransfer {
//    public static String url = "http://115.159.18.196:40/message/api/message-query/zhxy-import";//接口测试地址
    public static String url = "http://115.159.18.196/message/api/message-query/zhxy-import";//慧教云正式地址

    public static Log logger = LogFactory.getLog(NewsDataTransfer.class);

    public static SimpleDateFormat sdf =   new SimpleDateFormat("dd/MM/yyyy HH:mm:ss");
    public static SimpleDateFormat sdf1 =   new SimpleDateFormat("yyyy-MM-dd HH:mm:ss");


    public static void main(String[] args){
        RestTemplate restTemplate = new RestTemplate();
        FileReader fileReader = new FileReader("C:\\Users\\rc\\Desktop\\news.json");
        String jsonStr = fileReader.readString();
        JSONObject jsonObject = JSON.parseObject(jsonStr);
        JSONArray jsonArray = jsonObject.getJSONArray("RECORDS");

        for (int i=0; i<jsonArray.size();i++) {
            JSONObject item = jsonArray.getJSONObject(i);
            try {
                Date date = sdf.parse(item.getString("publishDate"));
                item.put("publishDate", date.getTime()/1000);
            } catch (ParseException e) {
                e.printStackTrace();
                item.put("publishDate", new Date().getTime());
            }

            String readers = item.getString("readers");

            String[] readerArr = readers.split(",");
            JSONArray sendeeUserInfoArr = new JSONArray();
            JSONArray readUserInfoArr = new JSONArray();
            for (int j = 0; j<readerArr.length; j++){
                //25194b88f9d147d3a78f32e9a9d5d34c|王荣|1|1|2018-01-02 13:50:14
                JSONObject sendeeUserInfo = new JSONObject();
                JSONObject readUserInfo = new JSONObject();
                String[] readerInfo = readerArr[j].split("\\|");
                if(readerInfo[0].length() != 32) continue;//personId长度为32 若不是则舍弃此消息接收者
                String personId = readerInfo[0];
                String name = readerInfo[1];
                String userType = readerInfo[2];
                String readStatus = readerInfo[3];//阅读状态  0－未读 1－已读 2-删除 3-彻底删除

                sendeeUserInfo.put("id", personId);
                sendeeUserInfo.put("name", name);
                sendeeUserInfo.put("userType", userType);
                sendeeUserInfoArr.add(sendeeUserInfo);

                if("1".equals(readStatus)){
                    String readTime = readerInfo[4];//阅读时间
                    readUserInfo.put("id", personId);
                    readUserInfo.put("name", name);
                    readUserInfo.put("userType", userType);
                    try {
                        //2018-11-23 09:52:28
                        Date date = sdf1.parse(readTime);
                        readUserInfo.put("readTime", date.getTime()/1000);
                    } catch (ParseException e) {
                        e.printStackTrace();
                        readUserInfo.put("readTime", new Date().getTime()/1000);
                    }
                    readUserInfoArr.add(readUserInfo);
                }
            }
            //如果是发送全体教职 readFLg 1表示全体教职工 4表示指定用户
            String readFlg = item.getString("readFlg");
            if("1".equals(readFlg)){
                sendeeUserInfoArr = new JSONArray();
                String allReaders = item.getString("allReaders");
                String[] allUserArr = allReaders.split(",");
                for (int k = 0;k<allUserArr.length; k++){
                    String[] readerInfo = allUserArr[k].split("\\|");
                    if(readerInfo[0].length() != 32) continue;//personId长度为32 若不是则舍弃此消息接收者
                    JSONObject sendeeUserInfo = new JSONObject();
                    String personId = readerInfo[0];
                    String name = readerInfo[1];
                    String userType = readerInfo[2];
                    sendeeUserInfo.put("id", personId);
                    sendeeUserInfo.put("name", name);
                    sendeeUserInfo.put("userType", userType);
                    sendeeUserInfoArr.add(sendeeUserInfo);
                }
            }

            if(sendeeUserInfoArr.size() == 0){
                System.out.println("没有接收人跳过：" + item.toJSONString());
                continue;//如果没有接收人 则此条通知舍弃
            }
            item.put("sendeeUserInfo", sendeeUserInfoArr);
            item.put("readUserInfo", readUserInfoArr);

            JSONObject param = new JSONObject();
            param.put("params", jsonArray.getJSONObject(i));
            JSONObject result = post(restTemplate, url, param);
            String newsId = jsonArray.getJSONObject(i).getString("zhxy_id");
            System.out.println(param.toJSONString());
            System.out.println(result.toJSONString());
            System.out.println("total:" + jsonArray.size() + "---now:" + (i+1) + "-----news_id:" + newsId + ">>>>>>>" + result.getString("message") + "----" + result.getString("desc"));

            logger.info(param.toJSONString());
            logger.info(result.toJSONString());
            logger.info("total:" + jsonArray.size() + "---now:" + (i+1) + "-----news_id:" + newsId + ">>>>>>>" + result.getString("message") + "----" + result.getString("desc"));
        }
    }

    public static JSONObject post(RestTemplate restTemplate ,String url, JSONObject param){
        HttpHeaders headers = new HttpHeaders();
        headers.setContentType(MediaType.APPLICATION_JSON_UTF8);
        HttpEntity<String> entity = new HttpEntity<String>(param.toJSONString(), headers);
        return JSON.parseObject(restTemplate.exchange(url, HttpMethod.POST, entity, String.class).getBody());
    }
}
