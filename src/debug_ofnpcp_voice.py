import requests
import urllib.parse
import os
import time
import random

def debug_ofnpcp_voice(text, token="123456", voice_name="zh-CN-XiaoxiaoNeural"):
    # 编码文本
    encoded_text = urllib.parse.quote(text)
    
    # 构建URL
    url = f"https://garrylord.vercel.app/api/aiyue?text={encoded_text}&voiceName={voice_name}"
    
    # 设置请求头
    headers = {
        "Authorization": f"Bearer {token}",
        "Content-Type": "text/plain",
        "Format": "audio-24khz-48kbitrate-mono-mp3"
    }
    
    try:
        # 发送GET请求
        print(f"[DEBUG] Sending request to: {url}")
        response = requests.get(url, headers=headers, timeout=30)
        
        # 打印响应信息
        print(f"[DEBUG] Response status code: {response.status_code}")
        print(f"[DEBUG] Response headers: {response.headers}")
        
        # 检查响应内容类型是否为音频
        if response.headers["Content-Type"] == "audio/mpeg":
            # 生成唯一文件名
            unique_id = f"{int(time.time())}_{random.randint(1000, 9999)}"
            temp_file = f"ofnpcp_temp_{unique_id}.mp3"
            
            # 保存音频文件
            with open(temp_file, "wb") as f:
                f.write(response.content)
            print(f"[DEBUG] Audio data saved to: {temp_file}")
        else:
            print(f"[ERROR] Unexpected response content type: {response.headers['Content-Type']}")
            
    except requests.exceptions.RequestException as e:
        print(f"[ERROR] HTTP request failed: {str(e)}")

if __name__ == "__main__":
    # 测试用例
    test_text = "最近过得怎么样，晦涩弗里曼？"
    debug_ofnpcp_voice(test_text) 