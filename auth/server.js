//引入模块
const http =require("http");
var URL = require('url');
const redis = require('redis')
var request = require('request');
var crypto = require('crypto');
var util = require('util');
const fs= require("fs");
//创建服务器
const server = http.createServer(function(req,res){
	const client = redis.createClient(6379, '127.0.0.1');
	client.auth('810302',function(err, reply) {
	 console.log(reply);
	});
	end = req.url.indexOf("?");
	//console.log(req.url.slice(0,end));
	res.writeHead(200,{"Content-Type":"text/html;charset=UTF-8",'Access-Control-Allow-Origin':'hiiboy.com:8888'})
	//请求的路由地址
	if(req.url == "/" || req.url=="/index.html"){
		
		fs.readFile("index.html",function(err,data){
			//加载的数据结束
			res.end(data)
		})
	}else if(req.url == "/auth" || req.url=="/draw.html"){
			fs.readFile("auth.html",function(err,data){
				//设置响应头
				//加载的数据结束
				res.end(data)
			})
	}else if(req.url=="/gold.html"){
			fs.readFile("gold.html",function(err,data){
				res.end(data)
			})
	}else if(req.url=="/oil.html"){
			fs.readFile("oil.html",function(err,data){
				res.end(data)
			})
	}else if(req.url == "/redis"){
		client.hgetall("user", function (err, obj) {	
			res.end(JSON.stringify(obj));
		});	
	}else if(req.url == "/bitmex"){
			if (req.method === 'POST') {
				var body = '';
				req.on('data', chunk => {
					body += chunk.toString(); // convert Buffer to string
				});
				req.on('end', () => {
					console.log(body);
					//var postBody = JSON.stringify(body);
					
					bitmex(body);
					res.end('ok');
				});
			}
			//var data = {symbol:"XBTUSD",orderQty:2,ordType:"Market"};
			//var postBody = JSON.stringify(data);
			//bitmex(postBody);
			res.end("open success");
	}else if(req.url.slice(0,end) == "/save"){
		var arg = URL.parse(req.url,true).query;  //方法二arg => { account: '001', auth: '1' }
		/*
		client.set('hello', JSON.stringify(arg)) // 注意，value会被转为字符串,所以存的时候要先把value 转为json字符串
		client.get('hello', function(err, value){
			console.log(value)
		})
		*/
		client.hset('user', arg.account,arg.auth, function(data) {
			  console.log(arg.account,"  ",arg.auth)
		})
		//res.writeHead(200,{'Access-Control-Allow-Origin':'hiiboy.com:8888'});
		res.end("save");
				
	}else{
			//加载的数据结束
			res.end('<h1> 所需内容未找到404 </h1>')
	}

}).listen(8888)

function bitmex(postBody)
{
var apiKey = "Ol8zB3C1KtB7IGeMp1i6Y1si";
var apiSecret = "aKMNONbyhZavg8xwSsB9DzO3_3b1oruJdQrcSh9N9nNI3T97";

var verb = 'POST',
  path = '/api/v1/order',
  expires = new Date().getTime() + (60 * 1000); // 1 min in the future
  //data = {symbol:"XBTUSD",orderQty:1,price:590,ordType:"Limit"};


var signature = crypto.createHmac('sha256', apiSecret).update(verb + path + expires + postBody).digest('hex');

var headers = {
  'content-type' : 'application/json',
  'Accept': 'application/json',
  'X-Requested-With': 'XMLHttpRequest',
  // This example uses the 'expires' scheme. You can also use the 'nonce' scheme. See
  // https://www.bitmex.com/app/apiKeysUsage for more details.
  'api-expires': expires,
  'api-key': apiKey,
  'api-signature': signature
};

const requestOptions = {
  headers: headers,
  url:'https://testnet.bitmex.com'+path,
  method: verb,
  body: postBody,
  proxy:'http://127.0.0.1:1080'
};

 request(requestOptions, function(error, response, body) {
   if (error) { console.log(error); }
   console.log(body);
 });

}