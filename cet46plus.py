import requests,random,socket,struct,threading

HEADERS = {
    'User-Agent':'Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:58.0) Gecko/20100101 Firefox/58.0',
    'Referer': 'http://www.chsi.com.cn/cet',
    'X-FORWARDED-FOR':'',
	'CLIENT-IP':''
}


xxdm = input("请输入前10位：")
xm = input("请输入考生姓名：")

thread_sum = 250  #此处修改线程数 请确定改数可以被500整除 否则无法覆盖全部准考证

ans = '未找到'

end_flag = False

class myThread (threading.Thread):
    def __init__(self, threadID, name,start_num,length):
        threading.Thread.__init__(self)
        self.threadID = threadID
        self.name = name
        self.start_num = start_num
        self.length = length
        self.stopped = False
    def run(self):
        #print(self.name+'运行中')
        main_loop(self, self.start_num,self.length)
        #print(self.name+'已停止')




def main_loop(thread_name,s,l):

    global end_flag,ans

    param = {
        'zkzh': '',
        'xm': ''}

    zkzh = int(xxdm + s + '01')

    param['xm'] = xm
    param['zkzh'] = zkzh

    while 1:
        if end_flag:
            return
        IP = socket.inet_ntoa(struct.pack('>I', random.randint(1, 0xffffffff)))
        HEADERS['X-FORWARDED-FOR'] = IP
        HEADERS['CLIENT-IP'] = IP
        try:
            rsp = requests.get('http://www.chsi.com.cn/cet/query',params=param, headers=HEADERS)
        except requests.exceptions.ConnectionError:
            continue
        except requests.exceptions.HTTPError:
            continue
        if '写作和翻译' in rsp.text:
            #print(param, '查询成功')
            # print(rsp.text)
            ans = param['zkzh']
            print('已找到准考证号：'+str(ans))
            end_flag = True
            input()
        else:
            #print(param, '尝试失败')
            zkzh += 1
            temp = zkzh - 31
            if temp % 100 == 0:
                zkzh = zkzh + 70
            if (zkzh-1) % (100*l) ==0:
                print(thread_name.name+'未找到准考证号')
                return
            param['zkzh'] = zkzh



for i in range(0,thread_sum):
    if i*(500//thread_sum)+1<10:
        myThread(i + 1, 'thread' + str(i),'00'+str(i*(500//thread_sum)+1),(500//thread_sum)).start()
    elif i*(500//thread_sum)+1<100:
        myThread(i + 1, 'thread' + str(i), '0' + str(i * (500//thread_sum) + 1), (500//thread_sum)).start()
    else:
        myThread(i + 1, 'thread' + str(i),str(i * (500//thread_sum) + 1), (500//thread_sum)).start()

print('运行中')



