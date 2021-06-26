import time
from pyvirtualdisplay import Display
from selenium import webdriver
from selenium.webdriver.support.wait import WebDriverWait
from selenium.webdriver.common.by import By
from selenium.webdriver.support import expected_conditions as EC
import subprocess
import json, os, sys

# git-webhook 主目录
scriptHomePath = "/home/lowking/git-webhook"

# 加启动配置
chrome_options = webdriver.ChromeOptions()
# 打开chrome浏览器
# 此步骤很重要，设置为开发者模式，防止被各大网站识别出来使用了Selenium
# chrome_options.add_experimental_option('excludeSwitches', ['enable-logging'])#禁止打印日志
chrome_options.add_experimental_option('excludeSwitches', ['enable-automation'])  # 跟上面只能选一个
# chrome_options.add_argument('--start-maximized')#最大化
chrome_options.add_argument('--incognito')  # 无痕隐身模式
chrome_options.add_argument("disable-cache")  # 禁用缓存
chrome_options.add_argument('disable-infobars')
chrome_options.add_argument('log-level=3')  # INFO = 0 WARNING = 1 LOG_ERROR = 2 LOG_FATAL = 3 default is 0
# chrome_options.add_argument('--headless')  # 浏览器不提供可视化页面. linux下如果系统不支持可视化不加这条会启动失败
chrome_options.add_argument(
    'user-agent="Mozilla/5.0 (iPhone; CPU iPhone OS 13_5 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/13.1.1 Mobile/15E148 Safari/604.1"')

telephone = ''
try:
    if "TELEPHONE" in os.environ:
        if len(os.environ["TELEPHONE"]) == 11:
            telephone = os.environ["TELEPHONE"]
            print("已获取并使用Env环境 TELEPHONE")
except:
    pass

print(telephone)
driver = None


def readCodeForTelephone(telephone):
    try:
        with open(f'../tmp/{telephone}.code', 'r') as code:
            codeStr = code.read()
            print(codeStr)
            return codeStr
    except:
        return 0


def jd_login():
    with Display(backend="xvfb", size=(500, 700)):
        print(sys.platform)
        try:
            if sys.platform == 'win32' or sys.platform == 'cygwin':
                driver = webdriver.Chrome(options=chrome_options, executable_path=r'./chromedriver.exe')
            else:
                driver = webdriver.Chrome(options=chrome_options, executable_path=r'./chromedriver')
            driver.set_window_size(375, 812)
        except:
            print('报错了!请检查你的环境是否安装谷歌Chrome浏览器！或者驱动【chromedriver.exe】版本是否和Chrome浏览器版本一致！\n驱动更新链接：http://npm.taobao.org/mirrors/chromedriver/')
            exit(0)

        driver.get('https://bean.m.jd.com/bean/signIndex.action')
        print(f'输入手机号{telephone}')

        WebDriverWait(driver, 600).until(EC.presence_of_element_located(
            (By.XPATH, "//input[@class='acc-input mobile J_ping']")
        ), "输入手机号超时").send_keys(telephone)
        print('点击发送验证码')
        WebDriverWait(driver, 600).until(EC.presence_of_element_located(
            (By.XPATH, "//button[@class='getMsg-btn text-btn J_ping timer active']")
        ), "点击发送验证码超时").click()
        print('准备接收验证码')

        count = 0
        preCode = readCodeForTelephone(telephone)
        while True:
            if count >= 120:
                exit(0)
            print('读取验证码')
            code = readCodeForTelephone(telephone)
            if preCode != code:
                print('获取到验证码，输入')
                WebDriverWait(driver, 60).until(EC.presence_of_element_located(
                    (By.XPATH, "//input[@class='acc-input J_ping authcode']")
                ), "输入验证码超时").send_keys(code)
                print('点击登录按钮')
                WebDriverWait(driver, 60).until(EC.presence_of_element_located(
                    (By.XPATH, "//a[@class='btn J_ping btn-active']")
                ), "点击登录超时").click()
                break
            count += 1
            time.sleep(1)

        time.sleep(2)
        driver.get_screenshot_as_file(f"{telephone}.png")
        print(f'截图')
        # print('判断是否登录成功')
        #
        # try:
        #     if WebDriverWait(driver, 120).until(EC.title_is(u"签到日历")):
        #         '''判断title,返回布尔值'''
        #         print('登录成功')
        # except:
        #     print('判断是否登录异常，退出')
        #     exit(2)
        #
        # print('判断是否登录结束')

        print('开始获取ck')
        jd_cookies = driver.get_cookies()
        print(jd_cookies)
        try:
            with open(f'cookies_tmp_{telephone}.txt', 'w') as fp:
                json.dump(jd_cookies, fp)
        except:
            print('保存cookie失败！')
        driver.quit()
        print('开始处理ck')
        try:
            with open(f'cookies_tmp_{telephone}.txt', 'r') as fp:
                cookies = json.load(fp)
                for cookie in cookies:
                    if cookie['name'] == "pt_key":
                        pt_key = '{}={};'.format(cookie['name'], cookie['value'])
                    elif cookie['name'] == "pt_pin":
                        pt_pin = '{}={};'.format(cookie['name'], cookie['value'])
                try:
                    pt_key
                    pt_pin
                    result = pt_key + pt_pin
                except:
                    pass
            print('执行更新ck脚本')
            print(result)
            result = result.replace(';', '\\;')
            os.system(f'bash {scriptHomePath}/commands/updateck.sh {result} |ts >> {scriptHomePath}/logs/jdCookieUpdate.log')
        except:
            print('读取cookie失败！')


if __name__ == '__main__':
    try:
        if telephone == '':
            print('未获取手机号，退出')
            exit(9)
        jd_login()
    except:
        pass
    finally:
        exit(0)
