package kr.co.turbosoft.api;

import java.text.SimpleDateFormat;
import java.util.Date;
import java.util.HashMap;
import java.util.List;

import javax.servlet.http.HttpServletRequest;

import org.apache.commons.lang.StringUtils;
import org.apache.log4j.Logger;
import org.codehaus.jackson.map.ObjectMapper;
import org.codehaus.jackson.type.TypeReference;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestMethod;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.ResponseBody;

import kr.co.turbosoft.dao.DataDao;
import kr.co.turbosoft.dao.UserDao;
import kr.co.turbosoft.util.KeyManager;
import net.sf.json.JSONArray;
import net.sf.json.JSONObject;

@Controller
public class UserAPI {
	static Logger log = Logger.getLogger(DataAPI.class.getName());

	static UserDao userDao = null;
	static DataDao dataDao = null;
	static DataAPI dataAPI = null;
	
	private HashMap<String, String> param, result, result2;
	private List<Object> resultList;
	private int resultIntegerValue;
	private String resultStringValue;

	public void setUserDao(UserDao userDao){
		this.userDao = userDao;
	}
	
	public void setDataDao(DataDao dataDao){
		this.dataDao = dataDao;
	}
	
	public void setDataAPI(DataAPI dataAPI){
		this.dataAPI = dataAPI;
	}
	
	//id, email 중복 체크
	@RequestMapping(value = "/cms/userChk/{textVal}/{textType}", method = RequestMethod.GET, produces="application/json;charset=UTF-8")
	@ResponseBody
	public String userChkService(@RequestParam("callback") String callback, @PathVariable("textVal") String textVal, @PathVariable("textType") String textType, Model model, HttpServletRequest request) {
		JSONObject resultJSON = new JSONObject();
		
		//token
		param = new HashMap<String, String>();
		
		try {
			if(textType != null && (textType.equalsIgnoreCase("ID") || textType.equalsIgnoreCase("EMAIL")) && textVal != null && textVal != ""){
				//id check
				param.put("textType", textType);
				param.put("textVal", textVal);
				
				result = userDao.selectUser(param);
				
				if(textType != null){
					if(result != null) {
						if(textType.equalsIgnoreCase("ID")){
							resultJSON.put("Code", 102);
							resultJSON.put("Message", Message.code102);
						}else if(textType.equalsIgnoreCase("EMAIL")){
							resultJSON.put("Code", 104);
							resultJSON.put("Message", Message.code104);
						}
					}else{
						if(textType.equalsIgnoreCase("ID")){
							resultJSON.put("Code", 101);
							resultJSON.put("Message", Message.code101);
						}else if(textType.equalsIgnoreCase("EMAIL")){
							resultJSON.put("Code", 103);
							resultJSON.put("Message", Message.code103);
						}
					}
				}
			}else{
				resultJSON.put("Code", 600);
				resultJSON.put("Message", Message.code600);
			}
		} catch (Exception e) {
			e.printStackTrace();
			resultJSON.put("Code", 800);
			resultJSON.put("Message", Message.code800);
		}
		
		return callback + "(" + resultJSON.toString() + ")";
	}
	
	//회원가입
	@RequestMapping(value = "/cms/join/{id}/{pass}/{email}/{iutype}", method = RequestMethod.GET, produces="application/json;charset=UTF-8")
	@ResponseBody
	public String joinService(@RequestParam("callback") String callback
			, @PathVariable("id") String id
			, @PathVariable("pass") String pass
			, @PathVariable("email") String email
			, @PathVariable("iutype") String iutype
			, Model model
			, HttpServletRequest reqeust) throws Exception{
		
		JSONObject resultJSON = new JSONObject();
		
		try {
			if(iutype != null && ("I".equals(iutype) || "U".equals(iutype)) && id != null && pass != null && email != null){
				param = new HashMap<String, String>();
				param.put("textId"	 , id		);
				param.put("textEmail", email	);
				param.put("iutype"	 , iutype	);
				param.put("textType" , "BOTH"	);
				
				result = userDao.selectUser(param);
				
				if(result == null) {
					param = new HashMap<String, String>();
					param.put("id"		 , id		);
					param.put("email"	 , email	);
					param.put("pass"	 , pass		);
					
					resultIntegerValue = userDao.insertUser(param);
						
					if(resultIntegerValue == 1) {
						resultIntegerValue = userDao.insertToken(param);
						
						if(resultIntegerValue == 1) {
							resultJSON.put("Code", 100);
							resultJSON.put("Message", Message.code100);
						} else {
							resultJSON.put("Code", 202);
							resultJSON.put("Message", Message.code202);
						}
					} else {
						resultJSON.put("Code", 300);
						resultJSON.put("Message", Message.code300);
					}
				} else {
					if("I".equals(iutype)){
						resultJSON.put("Code", 106);
						resultJSON.put("Message", Message.code106);
					}else if("U".equals(iutype)){
						param = new HashMap<String, String>();
						param.put("id"		, id	);
						param.put("pass"	, pass	);
						param.put("iutype"	, iutype);
						result = userDao.selectUser(param);
						if(result != null && result.size()>0){
							param.put("email"	, email	);
							resultIntegerValue = userDao.updateUser(param);
							
							if(resultIntegerValue == 1){
								resultJSON.put("Code", 100);
								resultJSON.put("Message", Message.code100);
							}else{
								resultJSON.put("Code", 300);
								resultJSON.put("Message", Message.code300);
							}
						}else{
							resultJSON.put("Code", 105);
							resultJSON.put("Message", Message.code105);
						}
					}
				}
			}else{
				resultJSON.put("Code", 600);
				resultJSON.put("Message", Message.code600);
			}
		} catch (Exception e) {
			e.printStackTrace();
			resultJSON.put("Code", 800);
			resultJSON.put("Message", Message.code800);
		}
		
		return callback + "(" + resultJSON.toString() + ")";
	}
	
	//id, pass 찾기
	@RequestMapping(value = "/cms/findUser/{textType}/{email}/{id}", method = RequestMethod.GET, produces="application/json;charset=UTF-8")
	@ResponseBody
	public String findUserService(@RequestParam("callback") String callback, 
			@PathVariable("textType") String textType,
			@PathVariable("email") String email,
			@PathVariable("id") String id,
			Model model, HttpServletRequest request) {
		JSONObject resultJSON = new JSONObject();
		
		param = new HashMap<String, String>();
		
		try {
			if(textType != null && ("findid".equals(textType) || "findpass".equals(textType)) && email != null && email != ""){
				//id check
				param.put("textType", textType);
				param.put("email", email);
				
				if("FINDPASS".equalsIgnoreCase(textType) && id != null && id != ""){
					param.put("id", id);
				}else{
					resultJSON.put("Code", 600);
					resultJSON.put("Message", Message.code600);
				}
				
				result = userDao.selectUser(param);
				
				if(result != null) {
					if("findid".equalsIgnoreCase(textType)){
						resultJSON.put("Code", 100);
						resultJSON.put("Message", Message.code100);
						resultJSON.put("Data", result.get("id"));
					}else if("findpass".equalsIgnoreCase(textType)){
						resultJSON.put("Code", 100);
						resultJSON.put("Message", Message.code100);
						resultJSON.put("Data", result.get("password"));
					}
				}else{
					resultJSON.put("Code", 105);
					resultJSON.put("Message", Message.code105);
				}
			}else{
				resultJSON.put("Code", 600);
				resultJSON.put("Message", Message.code600);
			}
		} catch (Exception e) {
			e.printStackTrace();
			resultJSON.put("Code", 800);
			resultJSON.put("Message", Message.code800);
		}
		
		return callback + "(" + resultJSON.toString() + ")";
	}
	
	//user login
	@RequestMapping(value = "/cms/login/{id}/{pass}", method = RequestMethod.GET, produces="application/json;charset=UTF-8")
	@ResponseBody
	public String loginService(@RequestParam("callback") String callback, @PathVariable("id") String id, @PathVariable("pass") String pass, Model model, HttpServletRequest request) {
		JSONObject resultJSON = new JSONObject();
		
		param = new HashMap<String, String>();
		
		//id check
		param.put("id", id);
		param.put("pass", pass);
		
		try {
			result = userDao.selectUser(param);
			
			if(result != null) {
				param.put("uid", String.valueOf(result.get("uid")));
				
				KeyManager keyManager = new KeyManager();
				String aes = null;
				
				try {
					aes = keyManager.genKey(id);
					param.put("aes", aes);
				} catch (Exception e) {
					// TODO Auto-generated catch block
					resultJSON.put("Code", 202);
					resultJSON.put("Message", Message.code202);
				}
				
				if(aes != null) {
					resultIntegerValue = userDao.updateToken(param);
					if(resultIntegerValue == 1) {
						resultJSON.put("Code", 100);
						resultJSON.put("Message", Message.code100);
						resultJSON.put("Data", result.get("type"));
						resultJSON.put("Token", aes);
					}else{
						resultJSON.put("Code", 202);
						resultJSON.put("Message", Message.code202);
					}
				}
			}else {
				resultJSON.put("Code", 105);
				resultJSON.put("Message", Message.code105);
			}
		} catch (Exception e) {
			e.printStackTrace();
			resultJSON.put("Code", 800);
			resultJSON.put("Message", Message.code800);
		}
		
		return callback + "(" + resultJSON.toString() + ")";
	}
	
	//type update
	@RequestMapping(value = "/cms/typeUpdate/{token}/{loginId}/{data}", method = RequestMethod.POST, produces="application/json;charset=UTF-8")
	@ResponseBody
	public String typeUpdateService(@RequestParam("callback") String callback
			, @PathVariable("token") String token
			, @PathVariable("loginId") String loginId
			, @PathVariable("data") String data
			, Model model
			, HttpServletRequest reqeust) throws Exception{
		
		JSONObject resultJSON = new JSONObject();
		
		//token
		param = new HashMap<String, String>();
		param.put("token", token);
		
		try {
			result = userDao.selectUid(param);

			if(result != null){
				boolean chkTokenToid = dataAPI.tokenToLoginId(token, loginId);
				if(!chkTokenToid){
					resultJSON.put("Code", 205);
					resultJSON.put("Message", Message.code205);
					return callback + "(" + resultJSON.toString() + ")";
				}
				
				if("ADMIN".equals(result.get("type"))){
					if(data != null && !"".equals(data) && !"null".equals(data)){
						ObjectMapper m = new ObjectMapper();
						try{
							List<HashMap<String, String>> saveList = m.readValue(data, new TypeReference<List<HashMap<String, String>>>() { });
							
							for(int i=0;i<saveList.size();i++){
								if(saveList.get(i) != null){
									boolean chkType = dataAPI.checkContentListType((String)saveList.get(i).get("type"), "userType");
									if(!chkType){
										resultJSON.put("Code", 600);
										resultJSON.put("Message", Message.code600);
										return callback + "(" + resultJSON.toString() + ")";
									}
									
									HashMap<String, String> tmpMap = new HashMap<String, String>();
									tmpMap = saveList.get(i);
									result = userDao.selectUser(tmpMap);
									
									if(!(result != null && result.size() > 0)){
										resultJSON.put("Code", 600);
										resultJSON.put("Message", Message.code600);
										return callback + "(" + resultJSON.toString() + ")";
									}
								}else{
									resultJSON.put("Code", 600);
									resultJSON.put("Message", Message.code600);
									return callback + "(" + resultJSON.toString() + ")";
								}
							}
							
							for(int i=0;i<saveList.size();i++){
								if(saveList.get(i) != null){
									HashMap<String, String> tmpMap = new HashMap<String, String>();
									tmpMap = saveList.get(i);
									tmpMap.put("typeChange","Y");
									resultIntegerValue = userDao.updateUser(tmpMap);
									if(resultIntegerValue != 1) {
										resultJSON.put("Code", 300);
										resultJSON.put("Message", Message.code300);
										break;
									}
								}else{
									resultJSON.put("Code", 600);
									resultJSON.put("Message", Message.code600);
									return callback + "(" + resultJSON.toString() + ")";
								}
							}
							resultJSON.put("Code", 100);
							resultJSON.put("Message", Message.code100);
						}catch(Exception e){
							resultJSON.put("Code", 600);
							resultJSON.put("Message", Message.code600);
						}
					}
				}else{
					resultJSON.put("Code", 500);
					resultJSON.put("Message", Message.code500);
				}
			}else{
				resultJSON.put("Code", 203);
				resultJSON.put("Message", Message.code203);
			}
		} catch (Exception e) {
			e.printStackTrace();
			resultJSON.put("Code", 800);
			resultJSON.put("Message", Message.code800);
		}
		
		return callback + "(" + resultJSON.toString() + ")";
	}
	
	//search user
	@RequestMapping(value = "/cms/searchUser/{token}/{loginId}/{searchType}/{searchText}/{sDate}/{eDate}/{pageNum}/{selUserNum}", method = RequestMethod.GET, produces="application/json;charset=UTF-8")
	@ResponseBody
	public String searchUserService(@RequestParam("callback") String callback
			, @PathVariable("token") String token
			, @PathVariable("loginId") String loginId
			, @PathVariable("searchType") String searchType
			, @PathVariable("searchText") String searchText
			, @PathVariable("sDate") String sDate
			, @PathVariable("eDate") String eDate
			, @PathVariable("pageNum") String pageNum
			, @PathVariable("selUserNum") String selUserNum
			, Model model, HttpServletRequest request) {
		JSONObject resultJSON = new JSONObject();
		
		//token
		param = new HashMap<String, String>();
		param.put("token", token);
		
		try {
			result = userDao.selectUid(param);
			
			if(result != null){
				boolean chkTokenToid = dataAPI.tokenToLoginId(token, loginId);
				if(!chkTokenToid){
					resultJSON.put("Code", 205);
					resultJSON.put("Message", Message.code205);
					return callback + "(" + resultJSON.toString() + ")";
				}
				
				if("ADMIN".equals(result.get("type"))){
					searchType = searchType.replace("&nbsp", "");
					searchText = searchText.replace("&nbsp", "");
					sDate = sDate.replace("&nbsp", "");
					eDate = eDate.replace("&nbsp", "");
					pageNum = pageNum.replace("&nbsp", "");
					selUserNum = selUserNum.replace("&nbsp", "");
					
					param.clear();
					if(pageNum != null && !"".equals(pageNum) && !"null".equals(pageNum) && StringUtils.isNumeric(pageNum)){
						param.put("pageNum", pageNum);
					}
					if(selUserNum != null && !"".equals(selUserNum) && !"null".equals(selUserNum) && StringUtils.isNumeric(selUserNum)){
						param.put("selUserNum", selUserNum);
					}
					
					boolean resCheck = false;
					if(searchType != null && !"".equals(searchType)){
						param.put("searchType", searchType);
						param.put("searchText", searchText);
						
						if("ID".equals(searchType) || "EMAIL".equals(searchType) || "TYPE".equals(searchType) && (searchText != null && !"".equals(searchText))){
							resCheck = true;
						}else if("REG_DATE".equals(searchType) && (sDate != null && !"".equals(sDate) || eDate!= null && !"".equals(eDate))){
							resCheck = true;
							int dCheck = 0;
							if(sDate != null && !"".equals(sDate) && !dataAPI.checkDate(sDate)){
								resCheck = false;
							}else if(sDate != null && !"".equals(sDate) && dataAPI.checkDate(sDate)){
								param.put("sDate", sDate);
								dCheck++;
							}
							if(eDate!= null && !"".equals(eDate) && !dataAPI.checkDate(eDate)){
								resCheck = false;
							}else if(eDate!= null && !"".equals(eDate) && dataAPI.checkDate(eDate)){
								param.put("eDate", eDate);
								dCheck++;
							}
							
							if(dCheck == 0){
								resCheck = false;
							}
						}
						
						if(!resCheck){
							resultJSON.put("Code", 600);
							resultJSON.put("Message", Message.code600);
							return callback + "(" + resultJSON.toString() + ")";
						}
					}
					
					int offset = 0;
					if(pageNum != null && !"".equals(pageNum) && !"null".equals(pageNum) && selUserNum != null && !"".equals(selUserNum) && !"null".equals(selUserNum)){
						if(StringUtils.isNumeric(pageNum) && StringUtils.isNumeric(selUserNum)){
							int tmpPage = Integer.valueOf(pageNum);
							int tmpContent = Integer.valueOf(selUserNum);
							offset = tmpContent * (tmpPage-1);
							param.put("offset", String.valueOf(offset));
						}else{
							resultJSON.put("Code", 600);
							resultJSON.put("Message", Message.code600);
							return callback + "(" + resultJSON.toString() + ")";
						}
					}
					
					resultList = userDao.selectAllUser(param);
					
					result = new HashMap<String, String>();
					result = userDao.selectAllUserLen(param);
					
					if(resultList != null && resultList.size() > 0) {
						resultJSON.put("Code", 100);
						resultJSON.put("Message", Message.code100);
						resultJSON.put("Data", JSONArray.fromObject(resultList));
						if(result != null){
							resultJSON.put("DataLen", result.get("total_cnt"));
						}
					}else {
						resultJSON.put("Code", 200);
						resultJSON.put("Message", Message.code200);
					}
						
						
				}else{
					resultJSON.put("Code", 500);
					resultJSON.put("Message", Message.code500);
				}
			}else{
				resultJSON.put("Code", 203);
				resultJSON.put("Message", Message.code203);
			}
		} catch (Exception e) {
			e.printStackTrace();
			resultJSON.put("Code", 800);
			resultJSON.put("Message", Message.code800);
		}
		
		return callback + "(" + resultJSON.toString() + ")";
	}
	
	@RequestMapping(value = "/cms/searchShareUser/{token}/{loginId}/{type}/{searchText}/{pageNum}/{selUserNum}/{shareIdx}/{shareKind}/{orderText}/{addShare}/{removeShare}", method = RequestMethod.GET, produces="application/json;charset=UTF-8")
	@ResponseBody
	public String searchShareUserService(@RequestParam("callback") String callback
			, @PathVariable("token") String token
			, @PathVariable("loginId") String loginId
			, @PathVariable("type") String type
			, @PathVariable("searchText") String searchText
			, @PathVariable("pageNum") String pageNum
			, @PathVariable("selUserNum") String selUserNum
			, @PathVariable("shareIdx") String shareIdx
			, @PathVariable("shareKind") String shareKind
			, @PathVariable("orderText") String orderText
			, @PathVariable("addShare") String addShare
			, @PathVariable("removeShare") String removeShare
			, Model model, HttpServletRequest request) {
		JSONObject resultJSON = new JSONObject();
		HashMap<String,Object> tempHash = new HashMap<String, Object>();
		String[] userArr = null;
		String[] addArr = null;
		String[] removeArr = null;
		
		//token
		param = new HashMap<String, String>();
		param.put("token", token);
		
		try {
			result = userDao.selectUid(param);
			
	  		if(result != null){
	  			boolean chkTokenToid = dataAPI.tokenToLoginId(token, loginId);
				if(!chkTokenToid){
					resultJSON.put("Code", 205);
					resultJSON.put("Message", Message.code205);
					return callback + "(" + resultJSON.toString() + ")";
				}
				
				searchText = searchText.replace("&nbsp", "");
				shareIdx = shareIdx.replace("&nbsp", "");
				shareKind = shareKind.replace("&nbsp", "");
				pageNum = pageNum.replace("&nbsp", "");
				selUserNum = selUserNum.replace("&nbsp", "");
				addShare = addShare.replace("&nbsp", "");
				removeShare = removeShare.replace("&nbsp", "");
				orderText = orderText.replace("&nbsp", "");
				
				tempHash.put("loginId", loginId);
				tempHash.put("searchText", searchText);
				if(pageNum != null && !"".equals(pageNum) && !"null".equals(pageNum) && StringUtils.isNumeric(pageNum)){
					tempHash.put("pageNum", pageNum);
				}
				if(selUserNum != null && !"".equals(selUserNum) && !"null".equals(selUserNum) && StringUtils.isNumeric(selUserNum)){
					tempHash.put("selUserNum", selUserNum);
				}
				
				if(orderText != null && !"".equals(orderText) && ("ASC".equals(orderText) || "DESC".equals(orderText))){
					tempHash.put("orderText", orderText);
				}else{
					tempHash.put("orderText", "ASC");
				}
				
				int offset = 0;
				if(pageNum != null && !"".equals(pageNum) && !"null".equals(pageNum) && selUserNum != null && !"".equals(selUserNum) && !"null". equals(selUserNum) ){
					if(StringUtils.isNumeric(pageNum) && StringUtils.isNumeric(selUserNum)){
						int tmpPage = Integer.valueOf(pageNum);
						int tmpContent = Integer.valueOf(selUserNum);
						offset = tmpContent * (tmpPage-1);
						tempHash.put("offset", String.valueOf(offset));
					}else{
						resultJSON.put("Code", 600);
						resultJSON.put("Message", Message.code600);
						return callback + "(" + resultJSON.toString() + ")";
					}
				}
				
				if(!dataAPI.checkContentListType(type, "searchShare") || !dataAPI.checkContentListType(shareKind, "shareKind")){
					resultJSON.put("Code", 600);
					resultJSON.put("Message", Message.code600);
					return callback + "(" + resultJSON.toString() + ")";
				}
				
				if(addShare != null && !"".equals(addShare) && !"null".equals(addShare)){
					if(!dataAPI.checkListIsNumber(addShare)){
						resultJSON.put("Code", 600);
						resultJSON.put("Message", Message.code600);
						return callback + "(" + resultJSON.toString() + ")";
					}
					addArr = addShare.split(",");
					tempHash.put("addArr", addArr);
				}
				
				if(removeShare != null && !"".equals(removeShare) && !"null".equals(removeShare)){
					if(!dataAPI.checkListIsNumber(removeShare)){
						resultJSON.put("Code", 600);
						resultJSON.put("Message", Message.code600);
						return callback + "(" + resultJSON.toString() + ")";
					}
					removeArr = removeShare.split(",");
					tempHash.put("removeArr", removeArr);
				}
				
				if(shareIdx != null && !"".equals(shareIdx) && !"null".equals(shareIdx) && StringUtils.isNumeric(shareIdx)){
					param.clear();
					param.put("shareIdx", shareIdx);
					param.put("shareKind", shareKind);
					resultList = userDao.selectShareUserList(param);
					if(resultList != null && resultList.size() > 0){
						userArr = new String[resultList.size()];
						
						for(int i=0;i<resultList.size();i++){
							HashMap<String, String> tmpMap = (HashMap<String, String>)resultList.get(i);
							if(tmpMap != null){
								userArr[i] = String.valueOf(tmpMap.get("uid"));
							}
						}
						tempHash.put("userArr", userArr);
						tempHash.put("shareIdx", shareIdx);
						tempHash.put("shareKind", shareKind);
					}
				}else if(!"search".equals(type)){
					resultJSON.put("Code", 600);
					resultJSON.put("Message", Message.code600);
					return callback + "(" + resultJSON.toString() + ")";
				}
				
				if(userArr == null){
					tempHash.put("searchOff", "Y");
				}
				
				resultList = userDao.selectShareUser(tempHash);
				
				if(type != null && "search".equals(type)){
					if(resultList != null && resultList.size() > 0){
						resultJSON.put("SearchYN", "Y");
					}else{
						tempHash.clear();
						tempHash.put("searchText", searchText);
						tempHash.put("pageNum", pageNum);
						tempHash.put("selUserNum", selUserNum);
						tempHash.put("orderText", orderText);
						resultList = userDao.selectShareUser(tempHash);
						resultJSON.put("SearchYN", "N");
					}
				}
				
				result = new HashMap<String, String>();
				result = userDao.selectShareUserLen(tempHash);
				
				if(resultList != null && resultList.size() > 0) {
					resultJSON.put("Code", 100);
					resultJSON.put("Message", Message.code100);
					resultJSON.put("Data", JSONArray.fromObject(resultList));
					if(result != null){
						resultJSON.put("DataLen", result.get("total_cnt"));
					}
				}
				else {
					resultJSON.put("Code", 200);
					resultJSON.put("Message", Message.code200);
				}
			}else{
				resultJSON.put("Code", 203);
				resultJSON.put("Message", Message.code203);
			}
		} catch (Exception e) {
			e.printStackTrace();
			resultJSON.put("Code", 800);
			resultJSON.put("Message", Message.code800);
		}
		
		return callback + "(" + resultJSON.toString() + ")";
	}
	
	//search share user
	@RequestMapping(value = "/cms/getShareUser/{token}/{loginId}/{shareIdx}/{shareType}", method = RequestMethod.GET, produces="application/json;charset=UTF-8")
	@ResponseBody
	public String searchUserService(@RequestParam("callback") String callback
			, @PathVariable("token") String token
			, @PathVariable("loginId") String loginId
			, @PathVariable("shareIdx") String shareIdx
			, @PathVariable("shareType") String shareType
			, Model model, HttpServletRequest request) {
		JSONObject resultJSON = new JSONObject();
		
		//token
		param = new HashMap<String, String>();
		param.put("token", token);
		
		try {
			result = userDao.selectUid(param);
			
			if(result != null){
				boolean chkTokenToid = dataAPI.tokenToLoginId(token, loginId);
				if(!chkTokenToid){
					resultJSON.put("Code", 205);
					resultJSON.put("Message", Message.code205);
					return callback + "(" + resultJSON.toString() + ")";
				}
				
				if(shareIdx != null && !"".equals(shareIdx) && StringUtils.isNumeric(shareIdx) && 
						shareType != null && !"".equals(shareType) && dataAPI.checkContentListType(shareType, "shareKind")){
					param.clear();
					param.put("loginId", loginId);
					param.put("shareIdx", shareIdx);
					param.put("shareKind", shareType);
					param.put("editUserChk", "Y");
					
					resultList = userDao.selectShareUserList(param);
					
					if(resultList != null && resultList.size() > 0) {
						resultJSON.put("Code", 100);
						resultJSON.put("Message", Message.code100);
						resultJSON.put("Data", JSONArray.fromObject(resultList));
					}else {
						resultJSON.put("Code", 200);
						resultJSON.put("Message", Message.code200);
					}
				}else{
					resultJSON.put("Code", 600);
					resultJSON.put("Message", Message.code600);
				}
			}else{
				resultJSON.put("Code", 203);
				resultJSON.put("Message", Message.code203);
			}
		} catch (Exception e) {
			e.printStackTrace();
			resultJSON.put("Code", 800);
			resultJSON.put("Message", Message.code800);
		}
		
		return callback + "(" + resultJSON.toString() + ")";
	}
	
	///////////////////////////////////////////////////////////////////////////////////////////////////////////
	//회원가입 API
	@RequestMapping(value = "/cms/joinUserOne/{id}/{pass}/{email}", method = RequestMethod.GET, produces="application/json;charset=UTF-8")
	@ResponseBody
	public String joinUserChkService(@RequestParam("callback") String callback
			, @PathVariable("id") String id
			, @PathVariable("pass") String pass
			, @PathVariable("email") String email
			, Model model
			, HttpServletRequest request) {
		JSONObject resultJSON = new JSONObject();
		
		//token
		param = new HashMap<String, String>();
		
		try {
			if(id != null && !"".equals(id) && pass != null && !"".equals(pass) && email != null && !"".equals(email)){
				//id check
				param.put("id", id);
				result = userDao.selectUser(param);
				
				//email check
				param.clear();
				param.put("email", email);
				result2 = userDao.selectUser(param);
				
				if(result != null && result.size() > 0 && result2 != null && result2.size() > 0){
					resultJSON.put("Code", 106);
					resultJSON.put("Message", Message.code106);
				}else if(result != null && result.size() > 0){
					resultJSON.put("Code", 102);
					resultJSON.put("Message", Message.code102);
				}else if(result2 != null && result2.size() > 0){
					resultJSON.put("Code", 104);
					resultJSON.put("Message", Message.code104);
				}else{
					param.clear();
					param.put("id", id);
					param.put("pass", pass);
					param.put("email", email);
					
					resultIntegerValue = userDao.insertUser(param);
					
					if(resultIntegerValue == 1) {
						resultIntegerValue = userDao.insertToken(param);
						
						if(resultIntegerValue == 1) {
							resultJSON.put("Code", 107);
							resultJSON.put("Message", Message.code107);
						} else {
							resultJSON.put("Code", 202);
							resultJSON.put("Message", Message.code202);
						}
					} else {
						resultJSON.put("Code", 300);
						resultJSON.put("Message", Message.code300);
					}
				}
			}else{
				resultJSON.put("Code", 600);
				resultJSON.put("Message", Message.code600);
			}
		} catch (Exception e) {
			e.printStackTrace();
			resultJSON.put("Code", 800);
			resultJSON.put("Message", Message.code800);
		}
		
		return callback + "(" + resultJSON.toString() + ")";
	}
	
	//토큰 발급 API
	@RequestMapping(value = "/cms/getToken/{id}/{pass}", method = RequestMethod.GET, produces="application/json;charset=UTF-8")
	@ResponseBody
	public String getTokenService(@RequestParam("callback") String callback
			, @PathVariable("id") String id
			, @PathVariable("pass") String pass
			, Model model
			, HttpServletRequest request) {
		JSONObject resultJSON = new JSONObject();
		
		param = new HashMap<String, String>();
		
		try {
			if(id != null && !"".equals(id) && pass != null && !"".equals(pass)){
				//id check
				param.put("id", id);
				param.put("pass", pass);
				
				result = userDao.selectUser(param);
				
				if(result != null) {
					param.put("searchToken", "Y");
					result2 = userDao.selectUid(param);
					
					if(result2 != null ){
						param.clear();
						param.put("uid", String.valueOf(result.get("uid")));
						
						if(result2.get("AES") != null && !"".equals(result2.get("AES"))){
							resultIntegerValue = userDao.updateTokenTime(param);
							if(resultIntegerValue == 1) {
								resultJSON.put("Code", 100);
								resultJSON.put("Message", Message.code100);
								resultJSON.put("Data", result.get("type"));
								resultJSON.put("Token", result2.get("AES"));
							}else{
								resultJSON.put("Code", 202);
								resultJSON.put("Message", Message.code202);
							}
						}else{
							KeyManager keyManager = new KeyManager();
							String aes = null;
							
							try {
								aes = keyManager.genKey(id);
								param.put("aes", aes);
							} catch (Exception e) {
								// TODO Auto-generated catch block
								resultJSON.put("Code", 202);
								resultJSON.put("Message", Message.code202);
							}
							
							if(aes != null) {
								resultIntegerValue = userDao.updateToken(param);
								if(resultIntegerValue == 1) {
									resultJSON.put("Code", 100);
									resultJSON.put("Message", Message.code100);
									resultJSON.put("Data", result.get("type"));
									resultJSON.put("Token", aes);
								}else{
									resultJSON.put("Code", 202);
									resultJSON.put("Message", Message.code202);
								}
							}
						}
					}else{
						resultJSON.put("Code", 105);
						resultJSON.put("Message", Message.code105);
					}
				}
				else {
					resultJSON.put("Code", 105);
					resultJSON.put("Message", Message.code105);
				}
			}else{
				resultJSON.put("Code", 600);
				resultJSON.put("Message", Message.code600);
			}
		} catch (Exception e) {
			e.printStackTrace();
			resultJSON.put("Code", 800);
			resultJSON.put("Message", Message.code800);
		}
		
		return callback + "(" + resultJSON.toString() + ")";
	}
}
