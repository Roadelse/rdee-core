#!/usr/bin/env python
# coding=utf-8

import sys
import os
import os.path
import argparse
import json
import smtplib
from email.header import Header
from email.mime.multipart import MIMEMultipart
from email.mime.text import MIMEText
from time import asctime


def send_email(sendto, subject, content, configDict=None, configfile=None, host=None, user=None, auth=None):
    if configDict:
        host = configDict["host"]
        user = configDict["user"]
        auth = configDict["auth"]
    elif configfile:
        if not configfile.endswith(".json"):
            raise TypeError(f"Unknown configfile: {configfile}")
        if not os.path.exists(configfile):
            raise FileNotFoundError(f"{configfile=}")
        with open(configfile, "r") as f:
            configDict = json.load(f)
        host = configDict["host"]
        user = configDict["user"]
        auth = configDict["auth"]
    else:
        if host is None or user is None or auth is None:
            raise TypeError("require host, user & auth without configfile / configDict")

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
    parser.add_argument('--host', help='ip:port')
    parser.add_argument('--user', '-u', help='example@mail.com')
    parser.add_argument('--auth', "-a", help="your authentication code from SMTP settings in your mail")
    parser.add_argument("--configfile", help="use a config file rather than setting each item via command argument")

    parser.add_argument('--sendto', '-s', required=True, help='example@mail.com')
    parser.add_argument('--content', "-c", default="", help="mail content")
    parser.add_argument('--title', "-t", required=True, help="mail title")

    args = parser.parse_args()

    if args.configfile:
        send_email(args.sendto, args.subject, args.content, configfile=args.configfile)
    else:
        send_email(args.sendto, args.subject, args.content, host=args.host, user=args.user, auth=args.auth)
