#!/usr/bin/env python
# coding=utf-8

import argparse
import smtplib
from email.header import Header
from email.mime.multipart import MIMEMultipart
from email.mime.text import MIMEText
from time import asctime

def send_email(sendto, subject, content, host, user, auth): # email_content是一个字符串
    # mail_host = "smtp.qq.com" # 这个去邮箱找
    # mail_port = 587
    # mail_user = "512334991@qq.com"
    # mail_auth_code = "?????"
    # mail_sender = user # 用mail_user 作为发送人
    mail_receivers = [sendto]
    message = MIMEMultipart()
    message['From'] = Header(user)  # 寄件人
    message['Subject'] = Header(subject)
    message.attach(MIMEText(content, 'plain', 'utf-8'))
    print("message is {}".format(message.as_string())) # debug用
    if ":" in host:
        _host, _port = host.split(":")
        smtpObj = smtplib.SMTP(_host, _port)
    else:
        smtpObj = smtplib.SMTP(host)

    # smtpObj.set_debuglevel(1) # 同样是debug用的
    smtpObj.login(user, auth) # 登陆
    smtpObj.sendmail(user, mail_receivers, message.as_string()) # 真正发送邮件就是这里


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="""send e-mail via python built-in smtp""")
    parser.add_argument('--host', required=True, help='ip:port')
    parser.add_argument('--user', '-u', required=True, help='example@mail.com')
    parser.add_argument('--to', '-t', required=True, help='example@mail.com')
    parser.add_argument('--authcode', "-a", required=True, help="your authentication code from SMTP settings in your mail")
    parser.add_argument('--content', "-c", default="", help="mail content")
    parser.add_argument('--subject', "-s", required=True, help="mail subject")

    args = parser.parse_args()

    send_email(args.to, args.subject, args.content, args.host, args.user, args.authcode)
