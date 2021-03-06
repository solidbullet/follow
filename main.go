package main

import (
	"bytes"
	"fmt"
	"io/ioutil"
	"net/http"
	"strings"
	"sync"

	"github.com/garyburd/redigo/redis"
)

const IN, OUT, BUY, SELL, BUYMAGIC, SELLMAGIC string = "0", "1", "0", "1", "888", "999"

var Eain sync.Map  //存放mt5发送过来的买入或者卖出单子
var Eaout sync.Map //存放mt5发送过来的买入或者卖出单子

var currency, gold, oil string

func mt5(w http.ResponseWriter, req *http.Request) {

	body, err := ioutil.ReadAll(req.Body)
	if err != nil {
		fmt.Printf("read body err,%v %v\n", err, body)
		return
	}
	post := bytes.TrimRight(body, "\x00")
	sc := strings.Split(string(post), ",")
	//12345,XAUUSD,0,0,0.02,1.1234,2.2345,88,mt4ticket,pos_id,accountid
	ticket := sc[0]
	info := sc[1:]
	entry := sc[2]
	t_type := sc[3]
	magic := sc[7]
	pos_id := sc[9]
	account_id := sc[10]
	//fmt.Printf("%t: ", account_id)
	//cond_in:多单买入单和空单买入单
	cond_in := (entry == IN && t_type == BUY && magic == BUYMAGIC) || (entry == IN && t_type == SELL && magic == SELLMAGIC) || (entry == IN && magic == "0")

	if cond_in && !No_auth(account_id) {
		Eain.Store(ticket, info)
	}
	Eain.Range(func(k, v interface{}) bool {
		k1 := k.(string)
		//v1 := v.([]string)
		cond_out := (entry == IN && t_type == SELL && magic == BUYMAGIC) || (entry == IN && t_type == BUY && magic == SELLMAGIC)
		if (k1 == pos_id && k1 != ticket) || cond_out { //能找到宿主，或者ea开的反向对冲单
			//fmt.Println(ticket, info)
			Eaout.Store(ticket, info)
		}
		return true
	})
	w.Write([]byte(post))
}
func monit(w http.ResponseWriter, req *http.Request) {
	body, err := ioutil.ReadAll(req.Body)
	if err != nil {
		fmt.Printf("read body err,%v %v\n", err, body)
		return
	}
	post := string(bytes.TrimRight(body, "\x00"))
	num := strings.LastIndex(post, "@")
	accountid := post[num+1 : len(post)]
	//fmt.Println(accountid == "227211") // 3
	if accountid == "227211" {
		currency = post
	}
	if accountid == "227325" {
		gold = post
	}
	if accountid == "1004423" {
		oil = post
	}
	w.Write([]byte("monit"))
}

func getorders(w http.ResponseWriter, req *http.Request) {
	w.Header().Add("Access-Control-Allow-Origin", "*")
	err := req.ParseForm()
	if err != nil {
		panic(err)
	}
	accountid := req.Form.Get("accountid")
	//fmt.Println(accountid) // 3
	//currency = "waihui"
	//gold = "huangjin"
	//oil = "yuanyou"
	//w.Header().Add("Access-Control-Allow-Origin", "*")
	if accountid == "227211" {
		w.Write([]byte(currency))
		//fmt.Println(currency)
	} else if accountid == "227325" {
		w.Write([]byte(gold))
	} else if accountid == "1004423" {
		w.Write([]byte(oil))
	} else {
		w.Write([]byte("accountid no exist"))
	}
}

func mt4(w http.ResponseWriter, req *http.Request) {
	var to_mt4 string
	body, err := ioutil.ReadAll(req.Body)
	if err != nil {
		fmt.Printf("read body err,%v %v\n", err, body)
		return
	}
	post := bytes.TrimRight(body, "\x00")

	sc := strings.Split(string(post), ",")
	if sc[0] == "openok" { //openok,mt5ticket,mt4ticket
		mapin, ok := Eain.Load(sc[1])
		if ok {
			t := mapin.([]string)
			t[7] = sc[2]
			Eain.Store(sc[1], t)
		}
		//fmt.Printf("跟单开仓成功")
	}
	if sc[0] == "closeallok" { //send("closeall,EAINkey,eaoutKEY")
		//fmt.Printf("delete map in & out ticket%v: ", sc)
		Eain.Delete(sc[1])
		Eaout.Delete(sc[2])
		//fmt.Printf("跟单全部平仓成功")
	}
	if sc[0] == "closehalfok" { //send("closehalf,EAINkey,eaoutKEY,0.01,mt4ticket") 5000
		Eaout.Delete(sc[2])
		mapin, ok := Eain.Load(sc[1])
		if ok {
			t := mapin.([]string)
			t[7] = sc[4]
			t[3] = sc[3]
			Eain.Store(sc[1], t)
		}
		//mapin1, _ := Eain.Load(sc[1])
		Eain.Load(sc[1])
		//fmt.Printf("跟单平一半成功")
	}
	if string(post) == "tick" {

		Eain.Range(func(key, value interface{}) bool {
			//XAUUSD,0,0,0.02,1.1234,2.2345,88,0,pos_id,最后一个0用来存放mt4发来的ticket
			key1 := key.(string)
			value1 := value.([]string)
			if value1[7] == "0" { //如果mapin中的买入单信号中最后一个是0，说明mt4尚未开单并返回单号
				mid_str := []string{"open", key1}
				mid_str = append(mid_str, value1...)
				to_mt4 = strings.Join(mid_str, ",")
				//fmt.Printf("send :%v\n", to_mt4) //发送信号1

			} else {
				Eaout.Range(func(k, v interface{}) bool {
					k1 := k.(string)
					v1 := v.([]string)
					//fmt.Println(v1)
					if v1[8] == key1 {
						res := []string{"CLOSE_HAND_TICKET", key1}
						res = append(res, value1...)
						res = append(res, k1)
						res = append(res, v1[3])
						to_mt4 = strings.Join(res, ",")
						fmt.Printf("OUT类型平仓%v到mt4\n", res) //发送信号2
					} else if v1[1] == IN && value1[2] != v1[2] && value1[0] == v1[0] {
						res := []string{"CLOSE_EA_TICKET", key1}
						res = append(res, value1...)
						res = append(res, k1)
						res = append(res, v1[3])
						to_mt4 = strings.Join(res, ",")
						//fmt.Printf("IN类型平仓%v到mt4\n", res) //发送信号3
					}
					return true
				})
			}
			return true
		})
	}
	w.Write([]byte(to_mt4))
}

func main() {
	http.HandleFunc("/mt5", mt5)
	http.HandleFunc("/mt4", mt4)
	http.HandleFunc("/monit", monit)
	http.HandleFunc("/getorders", getorders)
	http.ListenAndServe(":80", nil)
}

func No_auth(accountid string) bool {
	var ret bool = false
	c, err := redis.Dial("tcp", "127.0.0.1:6379")
	if err != nil {
		fmt.Println("connect to redis err", err.Error())
		return false
	}
	defer c.Close()
	res, err := c.Do("hget", "user", accountid)
	//fmt.Println(reflect.TypeOf(res))
	if err != nil {
		fmt.Println("hget failed", err.Error())
	} else {
		//fmt.Println(res)
		ret = (Byte2Int(res.([]byte))-48 == 1)
	}
	return ret
}

func Byte2Int(data []byte) int {
	var ret int = 0
	var len int = len(data)
	var i uint = 0
	for i = 0; i < uint(len); i++ {
		ret = ret | (int(data[i]) << (i * 8))
	}
	return ret
}
