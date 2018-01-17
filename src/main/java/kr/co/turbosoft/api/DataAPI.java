package kr.co.turbosoft.api;

import java.io.BufferedReader;
import java.io.File;
import java.io.FileInputStream;
import java.io.IOException;
import java.io.InputStreamReader;
import java.io.UnsupportedEncodingException;
import java.net.Authenticator;
import java.net.HttpURLConnection;
import java.net.PasswordAuthentication;
import java.net.URL;
import java.net.URLDecoder;
import java.net.URLEncoder;
import java.text.SimpleDateFormat;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.Date;
import java.util.HashMap;
import java.util.Iterator;
import java.util.List;
import java.util.Map;

import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.sql.DataSource;

import net.sf.json.JSONArray;
import net.sf.json.JSONObject;

import org.apache.commons.fileupload.FileItem;
import org.apache.commons.fileupload.disk.DiskFileItemFactory;
import org.apache.commons.fileupload.servlet.ServletFileUpload;
import org.apache.commons.lang.StringUtils;
import org.apache.commons.net.ftp.FTP;
import org.apache.commons.net.ftp.FTPClient;
import org.apache.commons.net.ftp.FTPFile;
import org.apache.commons.net.ftp.FTPReply;
import org.apache.log4j.Logger;
import org.codehaus.jackson.map.ObjectMapper;
import org.codehaus.jackson.type.TypeReference;
import org.json.XML;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.jdbc.datasource.DataSourceTransactionManager;
import org.springframework.stereotype.Controller;
import org.springframework.transaction.TransactionDefinition;
import org.springframework.transaction.TransactionStatus;
import org.springframework.transaction.support.DefaultTransactionDefinition;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestMethod;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.ResponseBody;

import com.oreilly.servlet.multipart.DefaultFileRenamePolicy;
import com.oreilly.servlet.multipart.FilePart;
import com.oreilly.servlet.multipart.FileRenamePolicy;
import com.oreilly.servlet.multipart.MultipartParser;
import com.oreilly.servlet.multipart.ParamPart;
import com.oreilly.servlet.multipart.Part;

import kr.co.turbosoft.dao.DataDao;
import kr.co.turbosoft.dao.UserDao;
import kr.co.turbosoft.util.ContentsSave;
import kr.co.turbosoft.util.SaveController;
import kr.co.turbosoft.util.VideoSaveController;

@Controller
public class DataAPI  {
	static Logger log = Logger.getLogger(DataAPI.class.getName());

	static DataDao dataDao = null;
	static UserDao userDao = null;
	
	@Autowired
	DataSource dataSource;
	
	private HashMap<String, String> param, result, result2, param2;
	private List<Object> resultList;
	private int resultIntegerValue;
	private String resultStringValue;

	public void setDataDao(DataDao dataDao){
		this.dataDao = dataDao;
	}
	public void setUserDao(UserDao userDao){
		this.userDao = userDao;
	}
	
	@Value("#{props['file.serverUrl']}")
	private String serverUrlStr;
	
	@Value("#{props['file.userId']}")
	private String userIdStr;
	
	@Value("#{props['file.userPass']}")
	private String userPassStr;
	
	@Value("#{props['file.portNum']}")
	private String portNumStr;
	
	@Value("#{props['file.saveFilePath']}")
	private String saveFilePathStr;

	@RequestMapping(value = "/cms/getbase", method = RequestMethod.GET, produces="application/json;charset=UTF-8")
	@ResponseBody
	public String baseService(@RequestParam("callback") String callback
			, Model model, HttpServletRequest request) {
		JSONObject resultJSON = new JSONObject();
		
		param = new HashMap<String, String>();
		
		try {
			//get Base
			resultList = dataDao.selectBase();
			
			if(resultList != null && resultList.size()>0) {
				resultJSON.put("Code", 100);
				resultJSON.put("Message", Message.code100);
				resultJSON.put("Data", resultList);
			}else {
				resultJSON.put("Code", 200);
				resultJSON.put("Message", Message.code200);
			}
		} catch (Exception e) {
			e.printStackTrace();
			resultJSON.put("Code", 800);
			resultJSON.put("Message", Message.code800);
		}
		
		return callback + "(" + resultJSON.toString() + ")";
	}
	
	@RequestMapping(value = "/cms/updateBase/{token}/{loginId}/{contentTab}/{contentTabType}/{contentNum}/{contentTabIdx}/{boardTab}/{boardNum}/{boardTabIdx}/{openAPI}/{latestView}/{mapZoom}", method = RequestMethod.POST, produces="application/json;charset=UTF-8")
	@ResponseBody
	public String updateBaseService(@RequestParam("callback") String callback
			, @PathVariable("token") String token
			, @PathVariable("loginId") String loginId
			, @PathVariable("contentTab") String contentTab
			, @PathVariable("contentTabType") String contentTabType
			, @PathVariable("contentNum") String contentNum
			, @PathVariable("contentTabIdx") String contentTabIdx
			, @PathVariable("boardTab") String boardTab
			, @PathVariable("boardNum") String boardNum
			, @PathVariable("boardTabIdx") String boardTabIdx
			, @PathVariable("openAPI") String openAPI
			, @PathVariable("latestView") String latestView
			, @PathVariable("mapZoom") String mapZoom
			, Model model, HttpServletRequest request) {
		JSONObject resultJSON = new JSONObject();
		
		//token
		param = new HashMap<String, String>();
		resultList = new ArrayList<Object>();
		param.put("token", token);
		HashMap<String, Object> objParam = new HashMap<String, Object>();
		
		try {
			result = userDao.selectUid(param);
			if(result != null){
				boolean chkTokenToid = tokenToLoginId(token, loginId);
				if(chkTokenToid){
					if("ADMIN".equals(result.get("type"))){
						boolean resChkBase = checkUpdateBase(contentTab, contentTabType, contentNum, contentTabIdx, boardTab, boardNum, boardTabIdx, openAPI, latestView, mapZoom);
						
						if(resChkBase){
							param.clear();
							param.put("openAPI", openAPI);
							param.put("latestView", latestView);
							param.put("mapZoom", mapZoom);
							
							resultIntegerValue = dataDao.updateBase(param);
							
							List<Object> removeList = new ArrayList<Object>();
							List<Map<String,Object>> newIdxArr = new ArrayList<Map<String,Object>>();
							List<Object> newProjectObjList = new ArrayList<Object>();
							List<Object> tmpNewProjectArr = new ArrayList<Object>();
							List<Map<String,Object>> tmpNewProjectArr2 = new ArrayList<Map<String,Object>>();
							List<Object> resList = new ArrayList<Object>();
							HashMap<String, Object> objParam2 = new HashMap<String, Object>();
							
							String[] cTabIdxArr = contentTabIdx.split(",");
							String[] bTabIdxArr = boardTabIdx.split(",");
							List<String> saveIdxArr = new ArrayList<String>();
							
							DefaultTransactionDefinition def = new DefaultTransactionDefinition();
							def.setPropagationBehavior(TransactionDefinition.PROPAGATION_REQUIRED);
							DataSourceTransactionManager txManager = new DataSourceTransactionManager(dataSource);
							TransactionStatus sts = txManager.getTransaction(def);

							try{
								boolean addIdx = false;
								if(cTabIdxArr != null && cTabIdxArr.length > 0){
									objParam = new HashMap<String, Object>();
									objParam.put("tabGroup", "content");
									resList = dataDao.selectTabList(objParam);
									
									for(int i=0;i<cTabIdxArr.length;i++){
										addIdx = false;
										tmpNewProjectArr = new ArrayList<Object>();
										for(int j=0;j<resList.size();j++){
											Map<String,Object> tmpMap = (Map<String,Object>)resList.get(j);
											String tmIdxStr = String.valueOf(tmpMap.get("tabidx"));
											if(tmpMap != null && cTabIdxArr[i].equals(tmIdxStr)){
												newIdxArr.add(tmpMap);
												addIdx = true;
												param = new HashMap<String, String>();
												param.put("tabIdx", tmIdxStr);
												tmpNewProjectArr = dataDao.selectAllProjectList(param);
												newProjectObjList.add(tmpNewProjectArr);
											}
										}
										if(!addIdx){
											newIdxArr.add(null);
											newProjectObjList.add(null);
										}
										if(cTabIdxArr[i] != null && !"&nbsp".equals(cTabIdxArr[i])){
											saveIdxArr.add(cTabIdxArr[i]);
										}
									}
									
									objParam = new HashMap<String, Object>();
									objParam.put("tabGroup", "content");
									objParam.put("saveIdxArr", saveIdxArr);
									if(saveIdxArr != null && saveIdxArr.size() > 0){
										removeList = dataDao.selectTabList(objParam);
										if(removeList != null && removeList.size() > 0){
											objParam = new HashMap<String, Object>();
											objParam.put("nowRightTabName", "content");
											objParam.put("removeList", removeList);
											resultIntegerValue = dataDao.deleteTab(objParam);
											if(resultIntegerValue > 0){
												for(int i=0;i<removeList.size();i++){
													Map<String,Object> tmpMap = (Map<String,Object>)removeList.get(i);
													if(tmpMap != null){
														param = new HashMap<String, String>();
														param.put("newTabIdx", "0");
														param.put("oldTabIdx", String.valueOf(tmpMap.get("tabidx")));
														resultIntegerValue += dataDao.updateTabIdxProject(param);
													}
												}
											}
										}
									}
									
									String[] tmpContentArr = contentTab.split(",");
									String[] tmpContentTypeArr = contentTabType.split(",");
									String[] tmpContentNumArr = contentNum.split(",");
									String tmpTabNameA = "";
									
									if(tmpContentArr != null && tmpContentArr.length > 0 && newIdxArr != null && newIdxArr.size() > 0){
										for(int i=0;i<tmpContentArr.length;i++){
											Map<String,Object> tmpMap = (Map<String,Object>)newIdxArr.get(i);
											tmpNewProjectArr2 = new ArrayList<Map<String,Object>>();
											if(tmpMap != null && !"&nbsp".equals(tmpContentArr[i])){
												param = new HashMap<String, String>();
												tmpTabNameA = tmpContentArr[i];
												if(tmpTabNameA != null){
													tmpTabNameA = dataReplaceFun(tmpTabNameA);
												}
												param.put("tabIdx", String.valueOf(i+1));
												param.put("tabName", tmpTabNameA);
												param.put("tabHeight", tmpContentNumArr[i]);
												param.put("tabType", tmpContentTypeArr[i]);
												param.put("tabGroup", "content");
												param.put("userId", loginId);
												param.put("idx", String.valueOf(tmpMap.get("idx")));
												resultIntegerValue = dataDao.updateTab(param);
												if(resultIntegerValue > 0){
													objParam2 = new HashMap<String, Object>();
													tmpNewProjectArr2 = (List<Map<String,Object>>)newProjectObjList.get(i);
													if(tmpNewProjectArr2 != null && tmpNewProjectArr2.size() > 0){
														objParam2.put("newTabIdx", String.valueOf(i+1));
														objParam2.put("oldTabProject", tmpNewProjectArr2);
														resultIntegerValue += dataDao.updateTabProjectIdx(objParam2);
													}
												}
											}else if(!"&nbsp".equals(tmpContentArr[i])){
												tmpTabNameA = tmpContentArr[i];
												if(tmpTabNameA != null){
													tmpTabNameA = dataReplaceFun(tmpTabNameA);
												}
												param = new HashMap<String, String>();
												param.put("tabIdx", String.valueOf(i+1));
												param.put("tabName", tmpTabNameA);
												param.put("tabHeight", tmpContentNumArr[i]);
												param.put("tabType", tmpContentTypeArr[i]);
												param.put("tabGroup", "content");
												param.put("userId", loginId);
												resultIntegerValue += dataDao.insertTab(param);
											}
										}
									}
								}
							
								//board
								if(bTabIdxArr != null && bTabIdxArr.length>0){
									newIdxArr = new ArrayList<Map<String,Object>>();
									saveIdxArr = new ArrayList<String>();
									removeList = new ArrayList<Object>();
									newProjectObjList = new ArrayList<Object>();
									tmpNewProjectArr = new ArrayList<Object>();
									tmpNewProjectArr2 = new ArrayList<Map<String,Object>>();
									objParam2 = new HashMap<String, Object>();
									objParam = new HashMap<String, Object>();
									
									objParam.put("tabGroup", "board");
									resList = dataDao.selectTabList(objParam);
									
									for(int i=0;i<bTabIdxArr.length;i++){
										addIdx = false;
										tmpNewProjectArr = new ArrayList<Object>();
										for(int j=0;j<resList.size();j++){
											Map<String,Object> tmpMap = (Map<String,Object>)resList.get(j);
											String tmIdxStr = String.valueOf(tmpMap.get("tabidx"));
											if(tmpMap != null && bTabIdxArr[i].equals(tmIdxStr)){
												newIdxArr.add(tmpMap);
												addIdx = true;
												param = new HashMap<String, String>();
												param.put("tabIdx", tmIdxStr);
												param.put("type", "list");
												param.put("loginId", loginId);
												tmpNewProjectArr = dataDao.selectBoardList(param);
												newProjectObjList.add(tmpNewProjectArr);
											}
										}
										if(!addIdx){
											newIdxArr.add(null);
											newProjectObjList.add(null);
										}
										if(bTabIdxArr[i] != null && !"&nbsp".equals(bTabIdxArr[i])){
											saveIdxArr.add(bTabIdxArr[i]);
										}
									}
									
									objParam = new HashMap<String, Object>();
									objParam.put("tabGroup", "board");
									objParam.put("saveIdxArr", saveIdxArr);
									if(saveIdxArr != null && saveIdxArr.size() > 0){
										removeList = dataDao.selectTabList(objParam);
										if(removeList != null && removeList.size() > 0){
											objParam = new HashMap<String, Object>();
											objParam.put("nowRightTabName", "board");
											objParam.put("removeList", removeList);
											resultIntegerValue = dataDao.deleteTab(objParam);
											if(resultIntegerValue >= 1){
												for(int i=0;i<removeList.size();i++){
													Map<String,Object> tmpMap = (Map<String,Object>)removeList.get(i);
													if(tmpMap != null){
														param = new HashMap<String, String>();
														param.put("newTabIdx", "0");
														param.put("oldTabIdx", String.valueOf(tmpMap.get("tabidx")));
														resultIntegerValue += dataDao.updateTabIdxBoard(param);
													}
												}
											}
										}
									}
									
									String[] tmpBoardArr = boardTab.split(",");
									String[] tmpBoardNumArr = boardNum.split(",");
									String tmpTabNameA = "";
									
									if(tmpBoardArr != null && tmpBoardArr.length > 0){
										for(int i=0;i<tmpBoardArr.length;i++){
											Map<String,Object> tmpMap = (Map<String,Object>)newIdxArr.get(i);
											tmpNewProjectArr2 = new ArrayList<Map<String,Object>>();
											if(tmpMap != null && !"&nbsp".equals(tmpBoardArr[i])){
												param = new HashMap<String, String>();
												tmpTabNameA = tmpBoardArr[i];
												if(tmpTabNameA != null){
													tmpTabNameA = dataReplaceFun(tmpTabNameA);
												}
												param.put("tabIdx", String.valueOf(i+1));
												param.put("tabName", tmpTabNameA);
												param.put("tabHeight", tmpBoardNumArr[i]);
												param.put("tabType", null);
												param.put("tabGroup", "board");
												param.put("userId", loginId);
												param.put("idx", String.valueOf(tmpMap.get("idx")));
												resultIntegerValue = dataDao.updateTab(param);
												if(resultIntegerValue > 0){
													objParam2 = new HashMap<String, Object>();
													tmpNewProjectArr2 = (List<Map<String,Object>>)newProjectObjList.get(i);
													if(tmpNewProjectArr2 != null && tmpNewProjectArr2.size() > 0){
														objParam2.put("newTabIdx", String.valueOf(i+1));
														objParam2.put("oldTabBoard", tmpNewProjectArr2);
														resultIntegerValue += dataDao.updateTabBoardIdx(objParam2);
													}
												}
											}else if(!"&nbsp".equals(tmpBoardArr[i])){
												param = new HashMap<String, String>();
												tmpTabNameA = tmpBoardArr[i];
												if(tmpTabNameA != null){
													tmpTabNameA = dataReplaceFun(tmpTabNameA);
												}
												param.put("tabIdx", String.valueOf(i+1));
												param.put("tabName", tmpTabNameA);
												param.put("tabHeight", tmpBoardNumArr[i]);
												param.put("tabType", null);
												param.put("tabGroup", "board");
												param.put("userId", loginId);
												resultIntegerValue += dataDao.insertTab(param);
											}
										}
									}
								}
							
							}catch(Exception e){
								txManager.rollback(sts);
								e.printStackTrace();
								resultJSON.put("Code", 800);
								resultJSON.put("Message", Message.code800);
								return callback + "(" + resultJSON.toString() + ")";
							}
							
							txManager.commit(sts);
							
							if(resultIntegerValue >= 1) {
								resultJSON.put("Code", 100);
								resultJSON.put("Message", Message.code100);
							}else {
								resultJSON.put("Code", 300);
								resultJSON.put("Message", Message.code300);
							}
						}else{
							resultJSON.put("Code", 600);
							resultJSON.put("Message", Message.code600);
						}
						
					}else{
						resultJSON.put("Code", 500);
						resultJSON.put("Message", Message.code500);
					}
				}else{
					resultJSON.put("Code", 205);
					resultJSON.put("Message", Message.code205);
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
	
	@RequestMapping(value = "/cms/getBoard/{type}/{token}/{loginId}/{pageNum}/{contentNum}/{tabIdx}/{idx}", method = RequestMethod.GET, produces="application/json;charset=UTF-8")
	@ResponseBody
	public String getBoardService(@RequestParam("callback") String callback
			, @PathVariable("type") String type
			, @PathVariable("token") String token
			, @PathVariable("loginId") String loginId
			, @PathVariable("pageNum") String pageNum
			, @PathVariable("contentNum") String contentNum
			, @PathVariable("tabIdx") String tabIdx
			, @PathVariable("idx") String idx
			, Model model, HttpServletRequest request) {
		JSONObject resultJSON = new JSONObject();
		
		param = new HashMap<String, String>();
		result = new HashMap<String, String>();
		List<Object> shareList = new ArrayList<Object>();
		resultList = new ArrayList<Object>();
		
		try {
			if(type != null && checkContentListType(type, "board")){
				loginId = loginId.replace("&nbsp", "");
				//token
				if(loginId != null && !"".equals(loginId)){
					param.clear();
					param.put("token", token);
					result = userDao.selectUid(param);
					
					if(result == null){
						resultJSON.put("Code", 203);
						resultJSON.put("Message", Message.code203);
						return callback + "(" + resultJSON.toString() + ")";
					}else{
						boolean chkTokenToid = tokenToLoginId(token, loginId);
						if(!chkTokenToid){
							resultJSON.put("Code", 205);
							resultJSON.put("Message", Message.code205);
							return callback + "(" + resultJSON.toString() + ")";
						}
					}
				}
				
				if("list".equals(type)){
					pageNum = pageNum.replace("&nbsp", "");
					contentNum = contentNum.replace("&nbsp", "");
					tabIdx = tabIdx.replace("&nbsp", "");
					
					param.put("type", type);
//					param.put("tabName", tabName);
					param.put("tabIdx", tabIdx);
					param.put("loginId", loginId);
					
					if(idx != null && !"".equals(idx) && !"null".equals(idx) && StringUtils.isNumeric(idx)){
						param.put("idx", idx);
					}
					
					if(pageNum != null && !"".equals(pageNum) && !"null".equals(pageNum) && StringUtils.isNumeric(pageNum)){
						param.put("pageNum", pageNum);
					}
					
					if(contentNum != null && !"".equals(contentNum) && !"null".equals(contentNum) && StringUtils.isNumeric(contentNum)){
						param.put("contentNum", contentNum);
					}
					
					if(pageNum != null && !"".equals(pageNum) && !"null".equals(pageNum) && contentNum != null && !"".equals(contentNum) && !"null".equals(contentNum)){
						if(StringUtils.isNumeric(pageNum) && StringUtils.isNumeric(contentNum)){
							int tmpPage = Integer.valueOf(pageNum);
							int tmpContent = Integer.valueOf(contentNum);
							int offset = tmpContent * (tmpPage-1);
							param.put("offset", String.valueOf(offset));
						}else{
							resultJSON.put("Code", 600);
							resultJSON.put("Message", Message.code600);
							return callback + "(" + resultJSON.toString() + ")";
						}
					}
					
					result = dataDao.selectBoardListLen(param);
				}else if("one".equals(type)){
					if(idx != null && !"".equals(idx) && !"null".equals(idx) && StringUtils.isNumeric(idx)){
						HashMap<String, String> shareParam = new HashMap<String, String>();
						shareParam.put("shareIdx", idx);
						shareParam.put("shareKind", "GeoCMS");
						shareList = userDao.selectShareUserList(shareParam);
						
						param.put("loginId", loginId);
						param.put("idx", idx);
					}else{
						resultJSON.put("Code", 600);
						resultJSON.put("Message", Message.code600);
						return callback + "(" + resultJSON.toString() + ")";
					}
				}else if("latest".equals(type)){
					contentNum = contentNum.replace("&nbsp", "");
					if(contentNum != null && !"".equals(contentNum) && !"null".equals(contentNum) && StringUtils.isNumeric(contentNum)){
						param.put("contentNum", contentNum);
					}
					param.put("loginId", loginId);
				}
				
				resultList = dataDao.selectBoardList(param);
				
				if(resultList != null && resultList.size() != 0) {
					resultJSON.put("Code", 100);
					resultJSON.put("Message", Message.code100);
					resultJSON.put("Data", JSONArray.fromObject(resultList));
					if(result != null){
						resultJSON.put("DataLen", result.get("total_cnt"));
					}
					if(shareList != null && shareList.size() > 0){
						resultJSON.put("shareList", shareList);
					}
				}else {
					resultJSON.put("Code", 200);
					resultJSON.put("Message", Message.code200);
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
	
	@RequestMapping(value = "/cms/saveBoardAll/{token}/{loginId}/{title}/{content}/{shareType}/{addShare}/{removeShare}/{editYes}/{editNo}", method = RequestMethod.POST, produces="application/json;charset=UTF-8")
	@ResponseBody
	public String saveBoardAllService(@RequestParam("callback") String callback
			, @PathVariable("token") String token
			, @PathVariable("loginId") String loginId
			, @PathVariable("title") String title
			, @PathVariable("content") String content
			, @PathVariable("shareType") String shareType
			, @PathVariable("addShare") String addShare
			, @PathVariable("removeShare") String removeShare
			, @PathVariable("editYes") String editYes
			, @PathVariable("editNo") String editNo
			, Model model, HttpServletRequest request) {
		JSONObject resultJSON = new JSONObject();
		param = new HashMap<String, String>();
		result = new HashMap<String, String>();
		
		//token
		param.clear();
		param.put("token", token);
		
		try {
			result = userDao.selectUid(param);
			
			if(result != null){
				boolean chkTokenToid = tokenToLoginId(token, loginId);
				if(!chkTokenToid){
					resultJSON.put("Code", 205);
					resultJSON.put("Message", Message.code205);
					return callback + "(" + resultJSON.toString() + ")";
				}
				
//				if(title != null && !"".equals(title) && !"null".equals(title)){ title = title.replaceAll("&sbsp","/"); }
//				if(content != null && !"".equals(content) && !"null".equals(content)){ content = content.replaceAll("&sbsp","/"); }
				title = dataReplaceFun(title);
				content = dataReplaceFun(content);
				if(addShare != null && !"".equals(addShare) && !"null".equals(addShare)){ addShare = addShare.replaceAll("&nbsp",""); }
				if(removeShare != null && !"".equals(removeShare) && !"null".equals(removeShare)){ removeShare = removeShare.replaceAll("&nbsp",""); }
				if(editYes != null && !"".equals(editYes) && !"null".equals(editYes)){ editYes = editYes.replaceAll("&nbsp",""); }
				if(editNo != null && !"".equals(editNo) && !"null".equals(editNo)){ editNo = editNo.replaceAll("&nbsp",""); }
				
				boolean chkData = true;
				if(title == null || title == "" || content == null || content == ""){
					chkData = false;
				}
				if(shareType == null || "".equals(shareType) || "null".equals(shareType) || !checkContentListType(shareType, "shareType")){
					chkData = false;
				}
				if(addShare != null && !"".equals(addShare) && !"null".equals(addShare) && !checkListIsNumber(addShare)){chkData = false;}
				if(removeShare != null && !"".equals(removeShare) && !"null".equals(removeShare) && !checkListIsNumber(removeShare)){chkData = false;}
				if(editYes != null && !"".equals(editYes) && !"null".equals(editYes) && !checkListIsNumber(editYes)){chkData = false;}
				if(editNo != null && !"".equals(editNo) && !"null".equals(editNo) && !checkListIsNumber(editNo)){chkData = false;}
				
				if(!chkData){
					resultJSON.put("Code", 600);
					resultJSON.put("Message", Message.code600);
					return callback + "(" + resultJSON.toString() + ")";
				}
				
				//update token time
				param.put("uid", String.valueOf(result.get("uid")));
				resultIntegerValue = userDao.updateTokenTime(param);
				
				////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
				String uploadType = "GeoCMS";
				
				//파일 정보 저장 변수
				ArrayList<String> fileNames = new ArrayList<String>();
				String filesStr = "";
				String saveUserPath = request.getSession().getServletContext().getRealPath("/")+ "upload";
				File saveUserPathDir = new File(saveUserPath);
			    if(!saveUserPathDir.exists()) saveUserPathDir.mkdir();
				
				//파일 업로드
				boolean isMultipart = ServletFileUpload.isMultipartContent(request); // 멀티파트인지 체크
				
				System.out.println("isMultipart : "+isMultipart);
				
				FTPClient ftp = null; // FTP Client 객체 
				FileInputStream fis = null; // File Input Stream 
				int reply = 0;
				
				try {
					if(isMultipart) {
						ftp = new FTPClient(); // FTP Client 객체 생성 
						ftp.setControlEncoding("UTF-8"); // 문자 코드를 UTF-8로 인코딩 
						ftp.connect(serverUrlStr, Integer.parseInt(portNumStr)); // 서버접속 " "안에 서버 주소 입력 또는 "서버주소", 포트번호 
						
						reply = ftp.getReplyCode();
						if(!FTPReply.isPositiveCompletion(reply)) {
							ftp.disconnect();
							resultJSON.put("Code", 400);
							resultJSON.put("Message", Message.code400);
							return callback + "(" + resultJSON.toString() + ")";
					    }
						
						if(!ftp.login(userIdStr, userPassStr)) {
							ftp.logout();
							resultJSON.put("Code", 400);
							resultJSON.put("Message", Message.code400);
							return callback + "(" + resultJSON.toString() + ")";
					    }
						
						ftp.setFileType(FTP.BINARY_FILE_TYPE);
					    ftp.enterLocalPassiveMode();

					    ftp.changeWorkingDirectory(saveFilePathStr +"/" +uploadType); // 작업 디렉토리 변경
					    reply = ftp.getReplyCode();
					    if (reply == 550) {
					    	ftp.makeDirectory(saveFilePathStr +"/" +uploadType);
					    	ftp.changeWorkingDirectory(saveFilePathStr +"/" +uploadType ); // 작업 디렉토리 변경
					    }
					    
						//--------------------------------------------------------------------------------------------
					    int uploadMaxSize = 2*1024*1024*1024; //1024MB = 1GB
						File tempDir = new File(saveUserPath+"/"+"tmp");
						File uploadDir = new File(saveUserPath+"/"+ uploadType);
//						
						if(!tempDir.exists()) tempDir.mkdir();
						if(!uploadDir.exists()) uploadDir.mkdir();
//						
						DiskFileItemFactory factory = new DiskFileItemFactory(uploadMaxSize, tempDir);
						ServletFileUpload upload = new ServletFileUpload(factory);
						upload.setSizeMax(uploadMaxSize);
						List items = upload.parseRequest(request);
						Iterator iter = items.iterator();
						while(iter.hasNext()) {
							FileItem item = (FileItem)iter.next();
							if(!item.isFormField()) {
								String fieldName = item.getFieldName();
								String fileName = item.getName();
								String contentType = item.getContentType();
								boolean isInMemory = item.isInMemory();
								long sizeInBytes = item.getSize();
								System.out.println("FieldName : "+fieldName);
								System.out.println("FileName : "+fileName);
								System.out.println("ContentType : "+contentType);
								System.out.println("IsInMemory : "+isInMemory);
								System.out.println("SizeInBytes : "+sizeInBytes);
								
								String uploadFilePath = uploadDir+"/"+fileName;
								int fileIndex = 1;
								File uploadFile;
								
								String prefix = uploadFilePath.substring(0, uploadFilePath.lastIndexOf("."));
								String suffix = uploadFilePath.substring(uploadFilePath.lastIndexOf("."));
								
								while((uploadFile = new File(uploadFilePath)).exists()) {
									uploadFilePath = prefix+"("+fileIndex+")"+suffix;
									fileIndex++;
									uploadFile = new File(uploadFilePath);
								}
								
								String changeFileName = uploadFilePath.substring(uploadFilePath.lastIndexOf("/")+1);
								String changFilePath = saveFilePathStr+"/"+uploadType+"/"+changeFileName;
								prefix = saveFilePathStr+"/"+uploadType+"/"+ fileName.substring(0, fileName.lastIndexOf("."));
								
								FTPFile[] fileN = ftp.listFiles("/"+changFilePath);
								while(fileN.length > 0) {
									changFilePath = prefix+"("+fileIndex+")"+suffix;
									fileIndex++;
									fileN = ftp.listFiles("/"+changFilePath);
								}
								
								changeFileName = changFilePath.substring(changFilePath.lastIndexOf("/")+1);
								
								uploadFilePath = uploadFilePath.substring(0, uploadFilePath.lastIndexOf("/"))+ "/"+ changeFileName;
								item.write(new File(uploadFilePath));
								item.delete();
								//////////////////////////////////////////
						        try {
						           fis = new FileInputStream(uploadFilePath);
						           boolean isSuccess = ftp.storeFile(changeFileName, fis);
						        
						           if(isSuccess) {
						              System.out.println(changFilePath + "파일 FTP 업로드 성공");
						           }
						        } catch(IOException ie) {
						           ie.printStackTrace();
						           resultJSON.put("Code", 400);
						           resultJSON.put("Message", Message.code400);
						           return callback + "(" + resultJSON.toString() + ")";
						        } finally {
						           File tmpF = new File(uploadFilePath);
						           if(fis != null) {
						              try {
						                 fis.close();
						              } catch(IOException ie) {
						                 ie.printStackTrace();
						                 resultJSON.put("Code", 400);
								         resultJSON.put("Message", Message.code400);
								         return callback + "(" + resultJSON.toString() + ")";
						              }finally{
						            	  if(tmpF.exists()){
								        	   tmpF.delete();
								          }
						              }
						           }
						           if(tmpF.exists()){
						        	   tmpF.delete();
						           }
						        }
								/////////////////////////////////////////
								
								//파일명 추가
								fileNames.add(changeFileName);
								filesStr += changeFileName + ",";
							}
						}
					}
				} catch (Exception e) {
					e.printStackTrace();
					resultJSON.put("Code", 400);
			        resultJSON.put("Message", Message.code400);
			        return callback + "(" + resultJSON.toString() + ")";
				}finally {
					if (ftp != null && ftp.isConnected()){
						try{ ftp.disconnect(); // 접속 끊기 
							
						} catch (IOException e){
							System.out.println("IO Exception : " + e.getMessage());
							resultJSON.put("Code", 400);
					        resultJSON.put("Message", Message.code400);
					        return callback + "(" + resultJSON.toString() + ")";
						}
					}
				}
				
				if(filesStr != null && !"".equals(filesStr)){
					filesStr = filesStr.substring(0, filesStr.length()-1);
				}	
				
				String makeContentStr = "";
				
				//이미지
				int tmpInt = 0;
				if(content != null && !"".equals(content) && !"null".equals(content)){
					String[] tmpContent = content.split("<img src=\"");
					for(int m= 0; m<tmpContent.length; m++){
						if(tmpContent[m] != null && tmpContent[m].contains("blob:http:")){
							String tmpText1 = tmpContent[m].substring(0, tmpContent[m].indexOf("\""));
							makeContentStr += "<img src=\"";
							makeContentStr += tmpContent[m].replace(tmpText1, fileNames.get(tmpInt));
							tmpInt ++;
						}else{
							makeContentStr += tmpContent[m];
						}
					}
					content = makeContentStr;
				}
				
				param.clear();
				param.put("loginId", loginId);
				param.put("title", title);
				param.put("content", content);
				param.put("files", filesStr);
				param.put("shareType", shareType);
				resultIntegerValue = dataDao.insertBoard(param);
				
				int saveIndex = 0;
				if(resultIntegerValue == 1) {
					if(param != null){
						if(param.get("idx") != null && param.get("idx") != ""){
							saveIndex = Integer.valueOf(String.valueOf(param.get("idx")));
						}
						
						if(shareType != null && "2".equals(shareType) && addShare != null && !"".equals(addShare) && !"null".equals(addShare)){
							HashMap<String, Object> tmpParam = new HashMap<String, Object>();
							
							String[] shareTList = addShare.split(",");
							tmpParam.put("shareTList", shareTList);
							tmpParam.put("shareIdx", param.get("idx"));
							tmpParam.put("shareKind", "GeoCMS");
							resultIntegerValue = userDao.insertShare(tmpParam);
							
							if(editYes != null && !"".equals(editYes) && !"null".equals(editYes)){
								String[] editList = editYes.split(",");
								tmpParam.put("editType", "Y");
								tmpParam.put("editList", editList);
								resultIntegerValue = userDao.updateShareEdit(tmpParam);
							}
						}
					}
				}
				
				if(resultIntegerValue > 0) {
					resultJSON.put("Code", 100);
					resultJSON.put("Message", Message.code100);
					resultJSON.put("Data", saveIndex);
				}else{
					resultJSON.put("Code", 300);
					resultJSON.put("Message", Message.code300);
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
	
	@RequestMapping(value = "/cms/updateBorderAll/{token}/{loginId}/{title}/{content}/{idx}/{shareType}/{addShare}/{removeShare}/{editYes}/{editNo}", method = RequestMethod.POST, produces="application/json;charset=UTF-8")
	@ResponseBody
	public String updateBorderService(@RequestParam("callback") String callback
			, @PathVariable("token") String token
			, @PathVariable("loginId") String loginId
			, @PathVariable("title") String title
			, @PathVariable("content") String content
			, @PathVariable("idx") String idx
			, @PathVariable("shareType") String shareType
			, @PathVariable("addShare") String addShare
			, @PathVariable("removeShare") String removeShare
			, @PathVariable("editYes") String editYes
			, @PathVariable("editNo") String editNo
			, Model model, HttpServletRequest request) {
		JSONObject resultJSON = new JSONObject();
		
		param = new HashMap<String, String>();
		
		//token
		param.put("token", token);
		
		try {
			result = userDao.selectUid(param);

			if(result != null){
				boolean chkTokenToid = tokenToLoginId(token, loginId);
				if(!chkTokenToid){
					resultJSON.put("Code", 205);
					resultJSON.put("Message", Message.code205);
					return callback + "(" + resultJSON.toString() + ")";
					
				}
				
//				if(title != null && !"".equals(title) && !"null".equals(title)){ title = title.replaceAll("&sbsp","/"); }
//				if(content != null && !"".equals(content) && !"null".equals(content)){ content = content.replaceAll("&sbsp","/"); }
				title = dataReplaceFun(title);
				content = dataReplaceFun(content);
				if(addShare != null && !"".equals(addShare) && !"null".equals(addShare)){ addShare = addShare.replaceAll("&nbsp",""); }
				if(removeShare != null && !"".equals(removeShare) && !"null".equals(removeShare)){ removeShare = removeShare.replaceAll("&nbsp",""); }
				if(editYes != null && !"".equals(editYes) && !"null".equals(editYes)){ editYes = editYes.replaceAll("&nbsp",""); }
				if(editNo != null && !"".equals(editNo) && !"null".equals(editNo)){ editNo = editNo.replaceAll("&nbsp",""); }
				
				boolean chkData = true;
				if(title == null || title == "" || content == null || content == ""){
					chkData = false;
				}
				if(shareType == null || "".equals(shareType) || "null".equals(shareType) || !checkContentListType(shareType, "shareType")){
					chkData = false;
				}
				if(addShare != null && !"".equals(addShare) && !"null".equals(addShare) && !checkListIsNumber(addShare)){chkData = false;}
				if(removeShare != null && !"".equals(removeShare) && !"null".equals(removeShare) && !checkListIsNumber(removeShare)){chkData = false;}
				if(editYes != null && !"".equals(editYes) && !"null".equals(editYes) && !checkListIsNumber(editYes)){chkData = false;}
				if(editNo != null && !"".equals(editNo) && !"null".equals(editNo) && !checkListIsNumber(editNo)){chkData = false;}
				
				if(!chkData){
					resultJSON.put("Code", 600);
					resultJSON.put("Message", Message.code600);
					return callback + "(" + resultJSON.toString() + ")";
				}

				//update token time
				param.put("uid", String.valueOf(result.get("uid")));
				resultIntegerValue = userDao.updateTokenTime(param);
				
				////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
				String uploadType = "GeoCMS";
				
				//파일 정보 저장 변수
				ArrayList<String> fileNames = new ArrayList<String>();
				String filesStr = "";
				String saveUserPath = request.getSession().getServletContext().getRealPath("/")+ "upload";
				File saveUserPathDir = new File(saveUserPath);
			    if(!saveUserPathDir.exists()) saveUserPathDir.mkdir();
				
				//파일 업로드
				boolean isMultipart = ServletFileUpload.isMultipartContent(request); // 멀티파트인지 체크
				
				System.out.println("isMultipart : "+isMultipart);
				
				FTPClient ftp = null; // FTP Client 객체 
				FileInputStream fis = null; // File Input Stream 
				int reply = 0;

				try {
					ftp = new FTPClient(); // FTP Client 객체 생성 
					ftp.setControlEncoding("UTF-8"); // 문자 코드를 UTF-8로 인코딩 
					ftp.connect(serverUrlStr, Integer.parseInt(portNumStr)); // 서버접속 " "안에 서버 주소 입력 또는 "서버주소", 포트번호 
					
					reply = ftp.getReplyCode();
					if(!FTPReply.isPositiveCompletion(reply)) {
						ftp.disconnect();
						resultJSON.put("Code", 400);
						resultJSON.put("Message", Message.code400);
						return callback + "(" + resultJSON.toString() + ")";
					}
					
					if(!ftp.login(userIdStr, userPassStr)) {
						ftp.logout();
						resultJSON.put("Code", 400);
						resultJSON.put("Message", Message.code400);
						return callback + "(" + resultJSON.toString() + ")";
					}
					
					ftp.setFileType(FTP.BINARY_FILE_TYPE);
					ftp.enterLocalPassiveMode();
					
					ftp.changeWorkingDirectory(saveFilePathStr +"/" +uploadType); // 작업 디렉토리 변경
					reply = ftp.getReplyCode();
					if (reply == 550) {
						ftp.makeDirectory(saveFilePathStr +"/" +uploadType);
						ftp.changeWorkingDirectory(saveFilePathStr +"/" +uploadType ); // 작업 디렉토리 변경
					}
					
					//--------------------------------------------------------------------------------------------
					
					List<String> oldFileNameArr = new ArrayList<String>();
					
					System.out.println("content : " + content);
					//이미지
					String tmpoldFileName = "";
					if(content != null && !"".equals(content) && !"null".equals(content)){
						String[] tmpContent = content.split("<img src=\"");
						for(int m= 0; m<tmpContent.length; m++){
							tmpoldFileName = "";
//							if(tmpContent[m] != null && tmpContent[m].contains("turbosoft1")){
							if(tmpContent[m] != null && tmpContent[m].contains("GeoCMS/")){
								String tmpText1 = tmpContent[m].substring(0, tmpContent[m].lastIndexOf("GeoCMS/"));
								tmpoldFileName = tmpContent[m].replace(tmpText1+"GeoCMS/", "");
								tmpoldFileName = tmpoldFileName.split("id=")[0];
								tmpoldFileName = tmpoldFileName.replace("\"", "");
								tmpoldFileName = tmpoldFileName.trim();
								oldFileNameArr.add(tmpoldFileName);
							}
						}
					}
					
					param.clear();
					param.put("loginId", loginId);
					param.put("idx", idx);
					param.put("type", "list");
					resultList = dataDao.selectBoardList(param);
					
					boolean chkOld = false;
					if(resultList != null && resultList.size()>0){
						HashMap<String, String> tmpMap = new HashMap<String, String>();
						param2 = new HashMap<String, String>();
						param2 = (HashMap<String, String>)resultList.get(0);
						if(param2 != null && param2.get("filename") != null && !"".equals(param2.get("filename"))){
							String tmpFileName1 = param2.get("filename");
							String[] tmpFileName2 = tmpFileName1.split(",");
							if(tmpFileName2 != null && tmpFileName2.length > 0){
								for(int k = 0; k<tmpFileName2.length; k++){
									chkOld = false;
									for(int l=0; l<oldFileNameArr.size();l++){
										if(oldFileNameArr.get(l).equals(tmpFileName2[k])){
											chkOld = true;
										}
									}
									if(!chkOld){
										try {
											boolean isSuccess = ftp.deleteFile(tmpFileName2[k]);//파일삭제
											
											if(isSuccess) {
												System.out.println(tmpFileName2[k] + "파일 FTP 삭제 성공");
											}
										} catch(IOException ie) {
											ie.printStackTrace();
											resultJSON.put("Code", 400);
											resultJSON.put("Message", Message.code400);
											return callback + "(" + resultJSON.toString() + ")";
										}
									}
								}
							}
						}else{
							resultJSON.put("Code", 200);
							resultJSON.put("Message", Message.code200);
							return callback + "(" + resultJSON.toString() + ")";
						}
					}else{
						resultJSON.put("Code", 200);
						resultJSON.put("Message", Message.code200);
						return callback + "(" + resultJSON.toString() + ")";
					}
					
					//--------------------------------------------------------------------------------------------
					if(isMultipart) {
						int uploadMaxSize = 2*1024*1024*1024; //1024MB = 1GB
						File tempDir = new File(saveUserPath+"/"+"tmp");
						File uploadDir = new File(saveUserPath+"/"+ uploadType);
						//
						if(!tempDir.exists()) tempDir.mkdir();
						if(!uploadDir.exists()) uploadDir.mkdir();
						//
						DiskFileItemFactory factory = new DiskFileItemFactory(uploadMaxSize, tempDir);
						ServletFileUpload upload = new ServletFileUpload(factory);
						upload.setSizeMax(uploadMaxSize);
						List items = upload.parseRequest(request);
						Iterator iter = items.iterator();
						while(iter.hasNext()) {
							FileItem item = (FileItem)iter.next();
							if(!item.isFormField()) {
								String fieldName = item.getFieldName();
								String fileName = item.getName();
								String contentType = item.getContentType();
								boolean isInMemory = item.isInMemory();
								long sizeInBytes = item.getSize();
								System.out.println("FieldName : "+fieldName);
								System.out.println("FileName : "+fileName);
								System.out.println("ContentType : "+contentType);
								System.out.println("IsInMemory : "+isInMemory);
								System.out.println("SizeInBytes : "+sizeInBytes);
								
								String uploadFilePath = uploadDir+"/"+fileName;
								int fileIndex = 1;
								File uploadFile;
								
								String prefix = uploadFilePath.substring(0, uploadFilePath.lastIndexOf("."));
								String suffix = uploadFilePath.substring(uploadFilePath.lastIndexOf("."));
								
								while((uploadFile = new File(uploadFilePath)).exists()) {
									uploadFilePath = prefix+"("+fileIndex+")"+suffix;
									fileIndex++;
									uploadFile = new File(uploadFilePath);
								}
								
								String changeFileName = uploadFilePath.substring(uploadFilePath.lastIndexOf("/")+1);
								String changFilePath = saveFilePathStr+"/"+uploadType+"/"+changeFileName;
								prefix = saveFilePathStr+"/"+uploadType+"/"+ fileName.substring(0, fileName.lastIndexOf("."));
								
								FTPFile[] fileN = ftp.listFiles("/"+changFilePath);
								while(fileN.length > 0) {
									changFilePath = prefix+"("+fileIndex+")"+suffix;
									fileIndex++;
									fileN = ftp.listFiles("/"+changFilePath);
								}
								
								changeFileName = changFilePath.substring(changFilePath.lastIndexOf("/")+1);
								
								uploadFilePath = uploadFilePath.substring(0, uploadFilePath.lastIndexOf("/"))+ "/"+ changeFileName;
								item.write(new File(uploadFilePath));
								item.delete();
								//////////////////////////////////////////
								try {
									fis = new FileInputStream(uploadFilePath);
									boolean isSuccess = ftp.storeFile(changeFileName, fis);
									
									if(isSuccess) {
										System.out.println(changFilePath + "파일 FTP 업로드 성공");
									}
								} catch(IOException ie) {
									ie.printStackTrace();
									resultJSON.put("Code", 400);
									resultJSON.put("Message", Message.code400);
									return callback + "(" + resultJSON.toString() + ")";
								} finally {
									File tmpF = new File(uploadFilePath);
									if(fis != null) {
										try {
											fis.close();
										} catch(IOException ie) {
											ie.printStackTrace();
											resultJSON.put("Code", 400);
											resultJSON.put("Message", Message.code400);
											return callback + "(" + resultJSON.toString() + ")";
										}finally{
											if(tmpF.exists()){
												tmpF.delete();
											}
										}
									}
									if(tmpF.exists()){
										tmpF.delete();
									}
								}
								/////////////////////////////////////////
								
								//파일명 추가
								fileNames.add(changeFileName);
							}
						}
					}
				} catch (Exception e) {
					e.printStackTrace();
					resultJSON.put("Code", 400);
					resultJSON.put("Message", Message.code400);
					return callback + "(" + resultJSON.toString() + ")";
				}finally {
					if (ftp != null && ftp.isConnected()){
						try{ ftp.disconnect(); // 접속 끊기 
					
						} catch (IOException e){
							System.out.println("IO Exception : " + e.getMessage());
							resultJSON.put("Code", 400);
							resultJSON.put("Message", Message.code400);
							return callback + "(" + resultJSON.toString() + ")";
						}
					}
				}
				
				String makeContentStr = "";
				String tmpoldFileName = "";
				//이미지
				int tmpInt = 0;
				if(content != null && !"".equals(content) && !"null".equals(content)){
					String[] tmpContent = content.split("<img src=\"");
					for(int m= 0; m<tmpContent.length; m++){
						tmpoldFileName = "";
						if(tmpContent[m] != null && tmpContent[m].contains("blob:http:")){
							String tmpText1 = tmpContent[m].substring(0, tmpContent[m].indexOf("\""));
							makeContentStr += "<img src=\"";
							makeContentStr += tmpContent[m].replace(tmpText1, fileNames.get(tmpInt));
							filesStr += fileNames.get(tmpInt) + ",";
							tmpInt ++;
//						}else if(tmpContent[m] != null && tmpContent[m].contains("turbosoft1")){
						}else if(tmpContent[m] != null && tmpContent[m].contains("GeoCMS/")){
							String tmpText1 = tmpContent[m].substring(0, tmpContent[m].lastIndexOf("GeoCMS/"));
							makeContentStr += "<img src=\"";
							tmpoldFileName = tmpContent[m].replace(tmpText1+"GeoCMS/", "");
							makeContentStr += tmpoldFileName;
							
							tmpoldFileName = tmpoldFileName.split("id=")[0];
							tmpoldFileName = tmpoldFileName.replace("\"", "");
							tmpoldFileName = tmpoldFileName.trim();
							filesStr += tmpoldFileName + ",";
						}else{
							makeContentStr += tmpContent[m];
						}
					}
					content = makeContentStr;
				}
				
				
				if(filesStr != null && !"".equals(filesStr)){
					filesStr = filesStr.substring(0, filesStr.length()-1);
				}
				
				/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
				
				param.clear();
				param.put("loginId", loginId);
				param.put("title", title);
				param.put("content", content);
				param.put("files", filesStr);
				param.put("idx", idx);
				param.put("shareType", shareType);
				resultIntegerValue = dataDao.updateBoard(param);
				
				if(resultIntegerValue == 1) {
					if(shareType != null && !"".equals(shareType) && !"null".equals(shareType)){
						HashMap<String, Object> tmpParam = new HashMap<String, Object>();
						tmpParam.put("shareIdx", idx);
						tmpParam.put("shareKind", "GeoCMS");
						
						if("2".equals(shareType)){
							if(addShare != null && !"".equals(addShare) && !"null".equals(addShare)){
								String[] shareTList = addShare.split(",");
								tmpParam.put("shareTList", shareTList);
								resultIntegerValue = userDao.insertShare(tmpParam);
							}
							if(removeShare != null && !"".equals(removeShare) && !"null".equals(removeShare)){
								String[] shareTList = removeShare.split(",");
								tmpParam.put("shareTList", shareTList);
								resultIntegerValue = userDao.deleteShare(tmpParam);
							}
							if(editYes != null && !"".equals(editYes) && !"null".equals(editYes)){
								String[] editList = editYes.split(",");
								tmpParam.put("editType", "Y");
								tmpParam.put("editList", editList);
								resultIntegerValue = userDao.updateShareEdit(tmpParam);
							}
							if(editNo != null && !"".equals(editNo) && !"null".equals(editNo)){
								String[] editList = editNo.split(",");
								tmpParam.put("editType", "N");
								tmpParam.put("editList", editList);
								resultIntegerValue = userDao.updateShareEdit(tmpParam);
							}
						}else{
							resultIntegerValue = userDao.deleteShare(tmpParam);
						}
					}
					
					resultJSON.put("Code", 100);
					resultJSON.put("Message", Message.code100);
				}else{
					resultJSON.put("Code", 300);
					resultJSON.put("Message", Message.code300);
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
	
	@RequestMapping(value = "/cms/getContent/{type}/{token}/{loginId}/{pageNum}/{contentNum}/{tabIdx}/{idx}", method = RequestMethod.GET, produces="application/json;charset=UTF-8")
	@ResponseBody
	public String getContentService(@RequestParam("callback") String callback
			, @PathVariable("type") String type
			, @PathVariable("token") String token
			, @PathVariable("loginId") String loginId
			, @PathVariable("pageNum") String pageNum
			, @PathVariable("contentNum") String contentNum
			, @PathVariable("tabIdx") String tabIdx
			, Model model, HttpServletRequest request) {
		JSONObject resultJSON = new JSONObject();
		
		param = new HashMap<String, String>();
		result = new HashMap<String, String>();
		
		try {
			if(type != null && checkContentListType(type, "contentB")){
				loginId = loginId.replace("&nbsp", "");
				pageNum = pageNum.replace("&nbsp", "");
				contentNum = contentNum.replace("&nbsp", "");
				tabIdx = tabIdx.replace("&nbsp", "");
				
				//token
				if("one".equals(type) || (loginId != null && !"".equals(loginId))){
					param.clear();
					param.put("token", token);
					result = userDao.selectUid(param);
					
					if(result == null){
						resultJSON.put("Code", 203);
						resultJSON.put("Message", Message.code203);
						return callback + "(" + resultJSON.toString() + ")";
					}else{
						boolean chkTokenToid = tokenToLoginId(token, loginId);
						if(!chkTokenToid){
							resultJSON.put("Code", 205);
							resultJSON.put("Message", Message.code205);
							return callback + "(" + resultJSON.toString() + ")";
						}
					}
				}
				
				param.put("type", type);
				param.put("loginId", loginId);
				param.put("tabIdx", tabIdx);
				
				if(pageNum != null && !"".equals(pageNum) && !"null".equals(pageNum) && StringUtils.isNumeric(pageNum)){
					param.put("pageNum", pageNum);
				}
				
				if(contentNum != null && !"".equals(contentNum) && !"null".equals(contentNum) && StringUtils.isNumeric(contentNum)){
					param.put("contentNum", contentNum);
				}
				
				if(pageNum != null && !"".equals(pageNum) && !"null".equals(pageNum) && contentNum != null && !"".equals(contentNum) && !"null".equals(contentNum)){
					if(StringUtils.isNumeric(pageNum) && StringUtils.isNumeric(contentNum)){
						int tmpPage = Integer.valueOf(pageNum);
						int tmpContent = Integer.valueOf(contentNum);
						int offset = tmpContent * (tmpPage-1);
						param.put("offset", String.valueOf(offset));
					}else{
						resultJSON.put("Code", 600);
						resultJSON.put("Message", Message.code600);
						return callback + "(" + resultJSON.toString() + ")";
					}
				}
				
				if("list".equals(type)){
					result = dataDao.selectContentListLen(param);
				}else if("latest".equals(type)){
					if(contentNum != null && !"".equals(contentNum) && !"null".equals(contentNum) && StringUtils.isNumeric(contentNum)){
						param.put("contentNum", contentNum);
					}
					param.put("loginId", loginId);
				}
				resultList = dataDao.selectContentList(param);
				
				if(resultList != null && resultList.size() != 0) {
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
	
	@RequestMapping(value = "/cms/getImage/{type}/{token}/{loginId}/{pageNum}/{contentNum}/{tabIdx}/{idx}", method = RequestMethod.GET, produces="application/json;charset=UTF-8")
	@ResponseBody
	public String getImageService(@RequestParam("callback") String callback
			, @PathVariable("type") String type
			, @PathVariable("token") String token
			, @PathVariable("loginId") String loginId
			, @PathVariable("pageNum") String pageNum
			, @PathVariable("contentNum") String contentNum
			, @PathVariable("tabIdx") String tabIdx
			, @PathVariable("idx") String idx
			, Model model, HttpServletRequest request) {
		JSONObject resultJSON = new JSONObject();
		
		param = new HashMap<String, String>();
		result = new HashMap<String, String>();
		List<Object> shareList = new ArrayList<Object>();
		
		try {
			if(type != null && checkContentListType(type, "content")){
				loginId = loginId.replace("&nbsp", "");
				loginId = loginId.replace("null", "");
				pageNum = pageNum.replace("&nbsp", "");
				contentNum = contentNum.replace("&nbsp", "");
				tabIdx = tabIdx.replace("&nbsp", "");
				idx = idx.replace("&nbsp", "");
				
				if(loginId != null && !"".equals(loginId)){
					//token
					param.clear();
					param.put("token", token);
					result = userDao.selectUid(param);
					
					if(result == null){
						resultJSON.put("Code", 203);
						resultJSON.put("Message", Message.code203);
						return callback + "(" + resultJSON.toString() + ")";
					}else{
						boolean chkTokenToid = tokenToLoginId(token, loginId);
						if(!chkTokenToid){
							resultJSON.put("Code", 205);
							resultJSON.put("Message", Message.code205);
							return callback + "(" + resultJSON.toString() + ")";
						}
					}
				}
				
				param.put("type", type);
				param.put("loginId", loginId);
				param.put("tabIdx", tabIdx);
				
				if(idx != null && !"".equals(idx) && !"null".equals(idx) && StringUtils.isNumeric(idx)){
					param.put("idx", idx);
				}
				if(pageNum != null && !"".equals(pageNum) && !"null".equals(pageNum) && StringUtils.isNumeric(pageNum)){
					param.put("pageNum", pageNum);
				}
				
				if(contentNum != null && !"".equals(contentNum) && !"null".equals(contentNum) && StringUtils.isNumeric(contentNum)){
					param.put("contentNum", contentNum);
				}
				
				if(pageNum != null && !"".equals(pageNum) && !"null".equals(pageNum) && contentNum != null && !"".equals(contentNum) && !"null".equals(contentNum)){
					if(StringUtils.isNumeric(pageNum) && StringUtils.isNumeric(contentNum)){
						int tmpPage = Integer.valueOf(pageNum);
						int tmpContent = Integer.valueOf(contentNum);
						int offset = tmpContent * (tmpPage-1);
						param.put("offset", String.valueOf(offset));
					}else{
						resultJSON.put("Code", 600);
						resultJSON.put("Message", Message.code600);
						return callback + "(" + resultJSON.toString() + ")";
					}
				}
				
				if("list".equals(type)){
					result = dataDao.selectImageListLen(param);
				}else if("one".equals(type)){
					if(idx != null && !"".equals(idx) && !"null".equals(idx) && StringUtils.isNumeric(idx)){
						param.put("shareIdx", idx);
						param.put("shareKind", "GeoPhoto");
						shareList = userDao.selectShareUserList(param);
					}else{
						resultJSON.put("Code", 600);
						resultJSON.put("Message", Message.code600);
						return callback + "(" + resultJSON.toString() + ")";
					}
				}
				resultList = dataDao.selectImageList(param);
				
				if(resultList != null && resultList.size() != 0) {
					resultJSON.put("Code", 100);
					resultJSON.put("Message", Message.code100);
					resultJSON.put("Data", JSONArray.fromObject(resultList));
					if(result != null){
						resultJSON.put("DataLen", result.get("total_cnt"));
					}
					if(shareList != null && shareList.size() > 0){
						resultJSON.put("shareList", shareList);
					}
				}else {
					resultJSON.put("Code", 200);
					resultJSON.put("Message", Message.code200);
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
	
	
	@RequestMapping(value = "/cms/saveImageAll/{token}/{loginId}/{title}/{content}/{projectIdx}/{droneType}", method = RequestMethod.POST, produces="application/json;charset=UTF-8")
	@ResponseBody
	public String saveImageAllService(@RequestParam("callback") String callback
		, @PathVariable("token") String token
		, @PathVariable("loginId") String loginId
		, @PathVariable("title") String title
		, @PathVariable("content") String content
		, @PathVariable("projectIdx") String projectIdx
		, @PathVariable("droneType") String droneType
		, Model model, HttpServletRequest request) {
		JSONObject resultJSON = new JSONObject();
		param = new HashMap<String, String>();
		param2 = new HashMap<String, String>();
		result = new HashMap<String, String>();
		HashMap<String, String> result2 = new HashMap<String, String>();
		HashMap<String, Object> objParam = new HashMap<String, Object>();
		List<Object> resList = new ArrayList<Object>();
		String shareType = "";
		int startSeq = 0;
		
		//token
		param.clear();
		param.put("token", token);
		result = userDao.selectUid(param);
		
		if(result != null){
			boolean chkTokenToid = tokenToLoginId(token, loginId);
			if(!chkTokenToid){
				resultJSON.put("Code", 205);
				resultJSON.put("Message", Message.code205);
				return callback + "(" + resultJSON.toString() + ")";
			}
			
			if(!(title != null && !"".equals(title) && content != null && !"".equals(content) && (droneType != null && ("&nbsp".equals(droneType) || "Y".equals(droneType))) &&
					projectIdx != null && !"".equals(projectIdx) && StringUtils.isNumeric(projectIdx))){
				resultJSON.put("Code", 600);
				resultJSON.put("Message", Message.code600);
				return callback + "(" + resultJSON.toString() + ")";
			}
			
			title = dataReplaceFun(title);
			content = dataReplaceFun(content);
			droneType = droneType.replaceAll("&nbsp","");
			
			String encode_title;
			String encode_content;
			try {
				encode_title = URLEncoder.encode(title, "EUC-KR");
				encode_content = URLEncoder.encode(content, "EUC-KR");
				
				title = URLDecoder.decode(encode_title, "EUC-KR");
				content = URLDecoder.decode(encode_content, "EUC-KR");
			} catch (UnsupportedEncodingException e) {
				e.printStackTrace();
				resultJSON.put("Code", 300);
				resultJSON.put("Message", Message.code300);
				return callback + "(" + resultJSON.toString() + ")";
			}
			
			param.clear();
			param.put("loginId", loginId);
			param.put("title", title);
			param.put("content", content);
			param.put("projectIdx", projectIdx);
			resultList = dataDao.selectProjectList(param);
			
			result2 = dataDao.selectProjectMaxSeq(param);
			if(result2 != null){
				if(result2.get("max_seq") != null && result2.get("max_seq") != ""){
					startSeq = Integer.valueOf(String.valueOf(result2.get("max_seq")));
				}
			}
			
			if(resultList != null && resultList.size() > 0){
				HashMap<String, String> tmpMap =  (HashMap<String, String>)resultList.get(0);
				if(tmpMap != null){
					shareType = String.valueOf(tmpMap.get("sharetype"));
				}else{
					resultJSON.put("Code", 700);
					resultJSON.put("Message", Message.code300);
					return callback + "(" + resultJSON.toString() + ")";
				}
			}else{
				resultJSON.put("Code", 700);
				resultJSON.put("Message", Message.code300);
				return callback + "(" + resultJSON.toString() + ")";
			}
			
			int uploadMaxSize = 1*1024*1024*1024; //1024MB = 1GB
			
			//update token time
			param.put("uid", String.valueOf(result.get("uid")));
			resultIntegerValue = userDao.updateTokenTime(param);
			
			//*************************************************************************************************************************
			String uploadType = "GeoPhoto";
			
			//파일 정보 저장 변수
			ArrayList<Map<String,String>> fileList = new ArrayList<Map<String,String>>();
			Map<String,String> fileMap = new HashMap<String, String>();
			String saveUserPath = request.getSession().getServletContext().getRealPath("/")+ "upload";
			File saveUserPathDir = new File(saveUserPath);
		    if(!saveUserPathDir.exists()) saveUserPathDir.mkdir();
		    File tempDir = new File(saveUserPath+"/"+"tmp");
			File uploadDir = new File(saveUserPath+"/"+ uploadType);
			int fileIndex = 1;
			List<String> saveFiles = new ArrayList<String>();
		    List<String> origFiles = new ArrayList<String>();
		
			//파일 업로드
			boolean isMultipart = ServletFileUpload.isMultipartContent(request); // 멀티파트인지 체크
			
			System.out.println("isMultipart : "+isMultipart);
			
			FTPClient ftp = null; // FTP Client 객체 
			FileInputStream fis = null; // File Input Stream 
			int reply = 0;
			
			DiskFileItemFactory factory = new DiskFileItemFactory(uploadMaxSize, tempDir);
			ServletFileUpload upload = new ServletFileUpload(factory);
			
			ContentsSave contentsSave = new ContentsSave();
			String reseultData = "";
			String[] reseultDataArr = null;
			String datalongitude = "";
			String datalatitude = "";
			String datatmpUploadFile = "";
			
			FileItem item = null;
			
			String logIdx = "";
			String fileName = "";
			String uploadFilePath = "";
			String prefix = "";
			String suffix = "";
			String changeFileName = "";
			
			DefaultTransactionDefinition def = new DefaultTransactionDefinition();
			def.setPropagationBehavior(TransactionDefinition.PROPAGATION_REQUIRED);
			// construct an appropriate transaction manager
			DataSourceTransactionManager txManager = new DataSourceTransactionManager(dataSource);
			TransactionStatus sts = txManager.getTransaction(def);
			
			try {
				if(isMultipart) {
					ftp = new FTPClient(); // FTP Client 객체 생성 
					ftp.setControlEncoding("UTF-8"); // 문자 코드를 UTF-8로 인코딩 
					ftp.connect(serverUrlStr, Integer.parseInt(portNumStr)); // 서버접속 " "안에 서버 주소 입력 또는 "서버주소", 포트번호 
					
					reply = ftp.getReplyCode();//a
					if(!FTPReply.isPositiveCompletion(reply)) {
						ftp.disconnect();
						resultJSON.put("Code", 400);
						resultJSON.put("Message", Message.code400);
						return callback + "(" + resultJSON.toString() + ")";
				    }
					
					if(!ftp.login(userIdStr, userPassStr)) {
						ftp.logout();
						resultJSON.put("Code", 400);
						resultJSON.put("Message", Message.code400);
						return callback + "(" + resultJSON.toString() + ")";
				    }
					
					ftp.setFileType(FTP.BINARY_FILE_TYPE);
				    ftp.enterLocalPassiveMode();
		
				    ftp.changeWorkingDirectory(saveFilePathStr +"/" +uploadType); // 작업 디렉토리 변경
				    reply = ftp.getReplyCode();
				    if (reply == 550) {
				    	ftp.makeDirectory(saveFilePathStr +"/" +uploadType);
				    	ftp.changeWorkingDirectory(saveFilePathStr +"/" +uploadType ); // 작업 디렉토리 변경
				    }
					//--------------------------------------------------------------------------------------------
				    if(!tempDir.exists()) tempDir.mkdir();
					if(!uploadDir.exists()) uploadDir.mkdir();
					
					upload.setSizeMax(uploadMaxSize);
					
					String viewTimeArr = "";
					
					try {
						MultipartParser parser = new MultipartParser(request, uploadMaxSize, true, true, "UTF-8");  /* file limit size of 1GB*/
			            Part _part;
			            while ((_part = parser.readNextPart()) != null) {
			                if (_part.isFile()) {
			                	FilePart fPart = (FilePart) _part;  // get some info about the file
			                    String name = fPart.getFileName();
			                    if (name != null) {
			                    	System.out.println("name " + name);
			                    	
			                    	FileRenamePolicy policy = new DefaultFileRenamePolicy();
			                    	fPart.setRenamePolicy(policy);
			                    	fPart.writeTo(uploadDir);
			                    	System.out.println("filePart.getFileName()) : " +fPart.getFileName());
//			                    	
			                    	saveFiles.add(saveUserPath+"/"+ "GeoPhoto"+"/"+fPart.getFileName());
			                    	origFiles.add(name);
			                    }
			                }else{
			                	ParamPart paramPart = (ParamPart) _part;
			                	System.out.println("paramPart " + new String(paramPart.getStringValue())); 
			                	viewTimeArr = new String(paramPart.getStringValue());
			                }
			                
			            }// end while 
					} catch (Exception e1) {
						e1.printStackTrace();
					}
					//////////////////////////////////////////////////////////
					
					String[] vTimeArr = null;
					if(viewTimeArr != null && !"".equals(viewTimeArr)){
						viewTimeArr = viewTimeArr.replace("[", "");
						viewTimeArr = viewTimeArr.replace("]", "");
						viewTimeArr = viewTimeArr.replaceAll("\"", "");
						vTimeArr = viewTimeArr.split(","); 
					}
					
					if(!(vTimeArr != null && vTimeArr.length > 0 && saveFiles != null && saveFiles.size() > 0 && origFiles != null && origFiles.size() > 0 && 
							vTimeArr.length == saveFiles.size() && saveFiles.size() == origFiles.size())){
						resultJSON.put("Code", 600);
						resultJSON.put("Message", Message.code600);
						return callback + "(" + resultJSON.toString() + ")";
					}
					
					int fileSeq = 0;
					int nowSeq = 0;
					
					int vIdx = 0;
					Date date1 = new Date();
					Date date2 = new Date();
					List<String> tmpViewArr = new ArrayList<String>();
					List<Integer> viewIdxArr = new ArrayList<Integer>();
					
				//	2017-11-09T10:04:13.917Z
					SimpleDateFormat transFormat = new SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss.SSS'Z'");
					for(int n = 0; n<vTimeArr.length;n++){
						System.out.println("vTimeArr[n : " + vTimeArr[n]);
						date1 = transFormat.parse(vTimeArr[n]);
						vIdx = 0;
						for(int m=0; m<vTimeArr.length;m++){
							date2 = transFormat.parse(vTimeArr[m]);
							int compare = date1.compareTo(date2);
							if(compare > 0){
								vIdx++;
							}else if(compare == 0 && n != m){
								if(Arrays.asList(tmpViewArr).contains(vTimeArr[n])){
									vIdx++;
								}else{
									tmpViewArr.add(vTimeArr[n]);
								}
							}
						}
						viewIdxArr.add(vIdx+1);
					}
					
					for(int k=0; k< origFiles.size(); k++){
						uploadFilePath = "";
						prefix = "";
						suffix = "";
						changeFileName = "";
						reseultData = "";
						reseultDataArr = null;
						datalongitude = "";
						datalatitude = "";
						datatmpUploadFile = "";
						resultIntegerValue = 0;
						fileMap = new HashMap<String, String>();
						
							fileName = origFiles.get(k);
							fileIndex = 1;
							param2.clear();
							param2.put("fileName", fileName);
							resList = dataDao.selectImageFileList(param2);
							
							changeFileName = fileName;
							prefix = fileName.substring(0, fileName.lastIndexOf("."));
							suffix = fileName.substring(fileName.lastIndexOf("."));
							
							while(resList != null && resList.size() > 0) {
								changeFileName = prefix+"("+fileIndex+")"+suffix;
								fileIndex++;
								param2.clear();
								param2.put("fileName", changeFileName);
								resList = dataDao.selectImageFileList(param2);
							}
							
							uploadFilePath = uploadDir + "/"+ changeFileName;
							
							System.out.println("uploadFile : "+uploadFilePath);
							
								//data save
								objParam.clear();
								objParam.put("sharetype", shareType);
								objParam.put("loginid", loginId);
								objParam.put("title", title);
								objParam.put("content", content);
								objParam.put("projectidx", projectIdx);
								objParam.put("filename", changeFileName);
								objParam.put("longitude", "0.0");
								objParam.put("latitude", "0.0");
								objParam.put("status", "PROGRESS");
								
								if(viewIdxArr.get(fileSeq) != null && !"".equals(viewIdxArr.get(fileSeq))){//-------------------------------------------------------------------------
									nowSeq = Integer.valueOf(String.valueOf(viewIdxArr.get(fileSeq)));//-------------------------------------------------------------------------
								}//-------------------------------------------------------------------------
								nowSeq += startSeq;//-------------------------------------------------------------------------
								objParam.put("seqnum", nowSeq);
								objParam.put("dronetype", droneType);
								fileSeq++;
								
								resultIntegerValue = dataDao.insertImage(objParam);
								
								fileMap.put("file", uploadFilePath);
								fileMap.put("idx", String.valueOf(objParam.get("idx")));
								fileList.add(fileMap);
								logIdx +=  String.valueOf(objParam.get("idx"))+",";
								
								if(resultIntegerValue == 1) {
									if(param != null){
										if(shareType != null && "2".equals(shareType)){
											param.put("shareIdx", String.valueOf(objParam.get("idx")));
											param.put("shareKind", "GeoPhoto");
											resultIntegerValue = userDao.insertShareFormProject(param);
										}
									}
								}
		//					}
//						}
					}//end while
				}//is multiple
			} catch (Exception e) {
				txManager.rollback(sts);
				e.printStackTrace();
				resultJSON.put("Code", 400);
				resultJSON.put("Message", Message.code400);
				return callback + "(" + resultJSON.toString() + ")";
			}
			txManager.commit(sts);
			
			param2 = new HashMap<String, String>();
			param2.put("loginId", loginId);
			param2.put("contentIdx", logIdx);
			param2.put("contentType", "GeoPhoto");
			param2.put("status", "PROGRESS");
			int resInt = dataDao.insertLog(param2);
			int logKey = 0; 
			
			if(resInt > 0){
				if(param2 != null && !"".equals(param2) && param2.get("idx") != null && !"".equals(param2.get("idx"))){
					logKey = Integer.valueOf(String.valueOf(param2.get("idx")));
					if(logKey <= 0){
						resultJSON.put("Code", 300);
						resultJSON.put("Message", Message.code300);
						return callback + "(" + resultJSON.toString() + ")";
					}
				}else{
					resultJSON.put("Code", 300);
					resultJSON.put("Message", Message.code300);
					return callback + "(" + resultJSON.toString() + ")";
				}
			}else{
				resultJSON.put("Code", 300);
				resultJSON.put("Message", Message.code300);
				return callback + "(" + resultJSON.toString() + ")";
			}
			
			
			imageSaveStart(loginId, String.valueOf(logKey), fileList, saveFiles, "imageFile");
			/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
			
			if(resultIntegerValue > 0) {
				resultJSON.put("Code", 100);
				resultJSON.put("Message", Message.code100);
				resultJSON.put("logKey", String.valueOf(logKey));
			}else{
				resultJSON.put("Code", 300);
				resultJSON.put("Message", Message.code300);
			}
		}else{
			resultJSON.put("Code", 203);
			resultJSON.put("Message", Message.code203);
		}
		
		return callback + "(" + resultJSON.toString() + ")";
	}

	@RequestMapping(value = "/cms/updateImage/{token}/{loginId}/{idx}/{title}/{content}/{shareType}/{addShareUser}/{removeShareUser}/{xmlData}/{editYes}/{editNo}", method = RequestMethod.POST, produces="application/json;charset=UTF-8")
	@ResponseBody
	public String updateImageService(@RequestParam("callback") String callback
			, @PathVariable("token") String token
			, @PathVariable("loginId") String loginId
			, @PathVariable("idx") String idx
			, @PathVariable("title") String title
			, @PathVariable("content") String content
			, @PathVariable("shareType") String shareType
			, @PathVariable("addShareUser") String addShareUser
			, @PathVariable("removeShareUser") String removeShareUser
			, @PathVariable("xmlData") String xmlData
			, @PathVariable("editYes") String editYes
			, @PathVariable("editNo") String editNo
			, Model model, HttpServletRequest request) {
		JSONObject resultJSON = new JSONObject();
		param = new HashMap<String, String>();
		result = new HashMap<String, String>();
		
		//token
		param.clear();
		param.put("token", token);
		
		try {
			result = userDao.selectUid(param);
			
			if(result != null){
				boolean chkTokenToid = tokenToLoginId(token, loginId);
				if(!chkTokenToid){
					resultJSON.put("Code", 205);
					resultJSON.put("Message", Message.code205);
					return callback + "(" + resultJSON.toString() + ")";
					
				}
				
				//update token time
				param.put("uid", String.valueOf(result.get("uid")));
				resultIntegerValue = userDao.updateTokenTime(param);
				
				title = dataReplaceFun(title);
				content = dataReplaceFun(content);
						
				addShareUser = addShareUser.replace("&nbsp", "");
				removeShareUser = removeShareUser.replace("&nbsp", "");
				if(xmlData != null && !"".equals(xmlData) && !"null".equals(xmlData)){
					xmlData = xmlData.replaceAll("&nbsp", "").replaceAll("&sbsp","/").replaceAll("&mbsp", "?").replaceAll("&pbsp", "#").replace("&obsp", ".");
				}
				editYes = editYes.replace("&nbsp", "");
				editNo = editNo.replace("&nbsp", "");
				
				if(!(title != null && !"".equals(title) && content != null && !"".equals(content) && 
						idx != null && !"".equals(idx) && StringUtils.isNumeric(idx) &&
								shareType != null && !"".equals(shareType) && checkContentListType(shareType,"shareType"))){
					resultJSON.put("Code", 600);
					resultJSON.put("Message", Message.code600);
					return callback + "(" + resultJSON.toString() + ")";
				}
				
				param.clear();
				param.put("loginId", loginId);
				param.put("idx", idx);
				param.put("title", title);
				param.put("content", content);
				param.put("shareType", shareType);
				param.put("xmlData", xmlData);
				
				resultIntegerValue = dataDao.updateImage(param);
				
				if(resultIntegerValue == 1) {
					if(shareType != null && !"".equals(shareType) && !"null".equals(shareType)){
						HashMap<String, Object> tmpParam = new HashMap<String, Object>();
						tmpParam.put("shareIdx", idx);
						tmpParam.put("shareKind", "GeoPhoto");
						
						if("2".equals(shareType)){
							if(addShareUser != null && !"".equals(addShareUser) && !"null".equals(addShareUser) && checkListIsNumber(addShareUser)){
								String[] shareTList = addShareUser.split(",");
								tmpParam.put("shareTList", shareTList);
								resultIntegerValue = userDao.insertShare(tmpParam);
							}
							if(removeShareUser != null && !"".equals(removeShareUser) && !"null".equals(removeShareUser) && checkListIsNumber(removeShareUser)){
								String[] shareTList = removeShareUser.split(",");
								tmpParam.put("shareTList", shareTList);
								resultIntegerValue = userDao.deleteShare(tmpParam);
							}
							if(editYes != null && !"".equals(editYes) && !"null".equals(editYes) && checkListIsNumber(editYes)){
								String[] editList = editYes.split(",");
								tmpParam.put("editType", "Y");
								tmpParam.put("editList", editList);
								resultIntegerValue = userDao.updateShareEdit(tmpParam);
							}
							if(editNo != null && !"".equals(editNo) && !"null".equals(editNo) && checkListIsNumber(editNo)){
								String[] editList = editNo.split(",");
								tmpParam.put("editType", "N");
								tmpParam.put("editList", editList);
								resultIntegerValue = userDao.updateShareEdit(tmpParam);
							}
						}else{
							resultIntegerValue = userDao.deleteShare(tmpParam);
						}
					}
					
					resultJSON.put("Code", 100);
					resultJSON.put("Message", Message.code100);
				}else{
					resultJSON.put("Code", 300);
					resultJSON.put("Message", Message.code300);
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
	
	@RequestMapping(value = "/cms/deleteContent/{token}/{loginId}/{type}/{idxArr}", method = RequestMethod.POST, produces="application/json;charset=UTF-8")
	@ResponseBody
	public String deleteImageService(@RequestParam("callback") String callback
			, @PathVariable("token") String token
			, @PathVariable("loginId") String loginId
			, @PathVariable("type") String type
			, @PathVariable("idxArr") String idxArr
			, Model model, HttpServletRequest request, HttpServletResponse response) {
		response.setHeader("Access-Control-Allow-Methods" , "POST, GET, OPTIONS, DELETE" );
		response.setHeader( "Access-Control-Max-Age" , "3600" );
		response.setHeader( "Access-Control-Allow-Headers" , "x-requested-with" );
		response.setHeader( "Access-Control-Allow-Origin" , "*" );

		JSONObject resultJSON = new JSONObject();
		param = new HashMap<String, String>();
		result = new HashMap<String, String>();
		
		String[] idxArray = null;
		String fileFull = "";
		
		//token
		param.clear();
		param.put("token", token);
		
		try {
			result = userDao.selectUid(param);
			
			if(result != null){
				boolean chkTokenToid = tokenToLoginId(token, loginId);
				if(!chkTokenToid){
					resultJSON.put("Code", 205);
					resultJSON.put("Message", Message.code205);
					return callback + "(" + resultJSON.toString() + ")";
					
				}
				
				if(!(type != null && !"".equals(type) && checkContentListType(type, "dataKind") && idxArr != null && !"".equals(idxArr) && checkListIsNumber(idxArr))){
					resultJSON.put("Code", 600);
					resultJSON.put("Message", Message.code600);
					return callback + "(" + resultJSON.toString() + ")";
				}
				
				//update token time
				param.put("uid", String.valueOf(result.get("uid")));
				resultIntegerValue = userDao.updateTokenTime(param);
				
				if(idxArr != null && !"".equals(idxArr) && !"null".equals(idxArr) ){
					idxArray = idxArr.split(",");
				}

				if(idxArray != null && idxArray.length > 0){
					try{
						FTPClient ftp = null; // FTP Client 객체 
						FileInputStream fis = null; // File Input Stream 
						int reply = 0;
						
						ftp = new FTPClient(); // FTP Client 객체 생성 
						ftp.setControlEncoding("UTF-8"); // 문자 코드를 UTF-8로 인코딩 
						ftp.connect(serverUrlStr, Integer.parseInt(portNumStr)); // 서버접속 " "안에 서버 주소 입력 또는 "서버주소", 포트번호 
						
						reply = ftp.getReplyCode();//a
						if(!FTPReply.isPositiveCompletion(reply)) {
							ftp.disconnect();
							resultJSON.put("Code", 400);
							resultJSON.put("Message", Message.code400);
							return callback + "(" + resultJSON.toString() + ")";
					    }
						
						if(!ftp.login(userIdStr, userPassStr)) {
							ftp.logout();
							resultJSON.put("Code", 400);
							resultJSON.put("Message", Message.code400);
							return callback + "(" + resultJSON.toString() + ")";
					    }
						
						ftp.setFileType(FTP.BINARY_FILE_TYPE);
					    ftp.enterLocalPassiveMode();

					    ftp.changeWorkingDirectory(saveFilePathStr +"/" +type); // 작업 디렉토리 변경
					    reply = ftp.getReplyCode();
					    if (reply == 550) {
					    	ftp.makeDirectory(saveFilePathStr +"/" +type);
					    	ftp.changeWorkingDirectory(saveFilePathStr +"/" +type ); // 작업 디렉토리 변경
					    }
						
						resultIntegerValue = 0;
						param.clear();
//						fileFull = "";
						
						param.put("loginId", loginId);
						for(int i=0;i<idxArray.length;i++){
							param.put("idx", idxArray[i]);
							resultList = new ArrayList<Object>();
							List<Object> childList = new ArrayList<Object>();
							HashMap<String, String> tmpChildParam = new HashMap<String, String>();
							
							if(type != null){
								if("GeoCMS".equals(type)){
									resultList = dataDao.selectBoardList(param);
								}else if("GeoPhoto".equals(type)){
									resultList = dataDao.selectImageList(param);
								}else if("GeoVideo".equals(type)){
									resultList = dataDao.selectVideoList(param);
									if(resultList != null && resultList.size() > 0){
										tmpChildParam.put("parentIdx", idxArray[i]);
										tmpChildParam.put("contentKind", type);
										childList = dataDao.selectContentChildList(tmpChildParam);
									}
								}
							}
							
							if(resultList != null && resultList.size() > 0){
								HashMap<String, String> tmpMap = (HashMap<String, String>)resultList.get(0);
								if(tmpMap != null){
									String tmpFileName = "";
									if(tmpMap.get("filename") != null && !"".equals(tmpMap.get("filename")) && !"null".equals(tmpMap.get("filename"))){
										tmpFileName = tmpMap.get("filename").replace("&nbsp", "");
									}
									
									if((tmpFileName != null && !"".equals(tmpFileName)) || "GeoVideo".equals(type)){
										if("GeoCMS".equals(type)){
											resultIntegerValue = dataDao.deleteBoard(param);
										}else if("GeoPhoto".equals(type)){
											resultIntegerValue = dataDao.deleteImage(param);
										}else if("GeoVideo".equals(type)){
											resultIntegerValue = dataDao.deleteVideo(param);
											dataDao.deleteContentChild(tmpChildParam);
										}
									}
									
									if(resultIntegerValue == 1) {
										resultJSON.put("Code", 100);
										resultJSON.put("Message", Message.code100);
										
										String[] tmpFileArr = null;
										if("GeoCMS".equals(type) || "GeoPhoto".equals(type)){
											tmpFileArr = tmpFileName.split(",");
										}else if("GeoVideo".equals(type)){
											if(childList != null && childList.size() > 0){
												tmpFileArr = new String[childList.size()];
												for(int j=0; j<childList.size(); j++){
													HashMap<String, String> tmpMap1 = (HashMap<String, String>)childList.get(j);
													if(tmpMap1 != null){
														tmpFileArr[j] = tmpMap1.get("filename");
													}
												}
											}
										}
										
										if(tmpFileArr != null && tmpFileArr.length > 0){
											for(int j=0; j<tmpFileArr.length; j++){
												try {
													boolean isSuccess = ftp.deleteFile(tmpFileArr[j]);//파일삭제
													if(isSuccess) {
														System.out.println(fileFull + "파일 FTP 삭제 성공");
													}
													
													if("GeoVideo".equals(type)){
														String tmpChild1 = tmpFileArr[j];
														tmpChild1 = tmpChild1.substring(0, tmpChild1.lastIndexOf("_ogg.ogg"));
														isSuccess = ftp.deleteFile(tmpChild1+ "_thumb.jpg");//thumbnail 파일삭제
														if(isSuccess) {
															System.out.println(tmpChild1+ "_thumb.jpg" + "파일 FTP 삭제 성공");
														}
														if(j == 0){
															isSuccess = ftp.deleteFile(tmpChild1+ "_ogg.gpx");//gpx 파일삭제
															if(isSuccess) {
																System.out.println(tmpChild1+ "_ogg.gpx" + "파일 FTP 삭제 성공");
															}
														}
													}
												} catch(IOException ie) {
													ie.printStackTrace();
													resultJSON.put("Code", 400);
													resultJSON.put("Message", Message.code400);
													return callback + "(" + resultJSON.toString() + ")";
												}
											}
										}
										
									}else{
										if("GeoCMS".equals(type)){
											resultIntegerValue = dataDao.deleteBoard(param);
										}
										
										if(resultIntegerValue == 1){
											resultJSON.put("Code", 100);
											resultJSON.put("Message", Message.code100);
										}else{
											resultJSON.put("Code", 300);
											resultJSON.put("Message", Message.code300);
											return callback + "(" + resultJSON.toString() + ")";
										}
									}
								}
							}else{
								resultJSON.put("Code", 300);
								resultJSON.put("Message", Message.code300);
							}
						}//for
					}catch(Exception e){
						e.printStackTrace();
						resultJSON.put("Code", 400);
						resultJSON.put("Message", Message.code400);
						return callback + "(" + resultJSON.toString() + ")";
					}
				}else{
					resultJSON.put("Code", 300);
					resultJSON.put("Message", Message.code300);
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
	
	@RequestMapping(value = "/cms/getMyContents/{viewType}/{token}/{loginId}/{pageNum}/{contentNum}", method = RequestMethod.GET, produces="application/json;charset=UTF-8")
	@ResponseBody
	public String getMyContentsService(@RequestParam("callback") String callback
			, @PathVariable("viewType") String viewType
			, @PathVariable("token") String token
			, @PathVariable("loginId") String loginId
			, @PathVariable("pageNum") String pageNum
			, @PathVariable("contentNum") String contentNum
			, Model model, HttpServletRequest request) {
		JSONObject resultJSON = new JSONObject();
		
		param = new HashMap<String, String>();
		result = new HashMap<String, String>();
		resultList = new ArrayList<Object>();
		
		//token
		param.clear();
		param.put("token", token);
		
		try {
			result = userDao.selectUid(param);
			
			if(result != null){
				boolean chkTokenToid = tokenToLoginId(token, loginId);
				if(!chkTokenToid){
					resultJSON.put("Code", 205);
					resultJSON.put("Message", Message.code205);
					return callback + "(" + resultJSON.toString() + ")";
				}
				
				pageNum = pageNum.replace("&nbsp", "");
				contentNum = contentNum.replace("&nbsp", "");
				
				if(viewType != null && checkContentListType(viewType, "viewType")){
					param.put("type", "list");
					param.put("loginId", loginId);
					
					if(pageNum != null && !"".equals(pageNum) && !"null".equals(pageNum) && StringUtils.isNumeric(pageNum)){
						param.put("pageNum", pageNum);
					}
					
					if(contentNum != null && !"".equals(contentNum) && !"null".equals(contentNum) && StringUtils.isNumeric(contentNum)){
						param.put("contentNum", contentNum);
					}
					
					if(pageNum != null && !"".equals(pageNum) && !"null".equals(pageNum) && contentNum != null && !"".equals(pageNum) && !"null".equals(contentNum)){
						if(StringUtils.isNumeric(pageNum) && StringUtils.isNumeric(contentNum)){
							int tmpPage = Integer.valueOf(pageNum);
							int tmpContent = Integer.valueOf(contentNum);
							int offset = tmpContent * (tmpPage-1);
							param.put("offset", String.valueOf(offset));
						}else{
							resultJSON.put("Code", 600);
							resultJSON.put("Message", Message.code600);
							return callback + "(" + resultJSON.toString() + ")";
						}
					}
					
					if("GeoCMS".equals(viewType)){
						resultList = dataDao.selectBoardList(param);
						result = dataDao.selectBoardListLen(param);
					}
					else if("GeoPhoto".equals(viewType)){
						resultList = dataDao.selectImageList(param);
						result = dataDao.selectImageListLen(param);
					}else if("GeoVideo".equals(viewType)){
						resultList = dataDao.selectVideoList(param);
						result = dataDao.selectVideoListLen(param);
					}else if("marker".equals(viewType)){
						param.put("type", "marker");
						param.put("myContentMarker", "Y");
						resultList = dataDao.selectContentList(param);
					}
					if(resultList != null && resultList.size() != 0) {
						resultJSON.put("Code", 100);
						resultJSON.put("Message", Message.code100);
						resultJSON.put("Data", JSONArray.fromObject(resultList));
						resultJSON.put("DataLen", result.get("total_cnt"));
					}
					else {
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
	
	@RequestMapping(value = "/cms/getVideo/{type}/{token}/{loginId}/{pageNum}/{contentNum}/{tabIdx}/{idx}", method = RequestMethod.GET, produces="application/json;charset=UTF-8")
	@ResponseBody
	public String getVideoService(@RequestParam("callback") String callback
			, @PathVariable("type") String type
			, @PathVariable("token") String token
			, @PathVariable("loginId") String loginId
			, @PathVariable("pageNum") String pageNum
			, @PathVariable("contentNum") String contentNum
			, @PathVariable("tabIdx") String tabIdx
			, @PathVariable("idx") String idx
			, Model model, HttpServletRequest request) {
		JSONObject resultJSON = new JSONObject();
		
		param = new HashMap<String, String>();
		result = new HashMap<String, String>();
		List<Object> shareList = new ArrayList<Object>();
		
		if(type != null && checkContentListType(type, "content")){
			loginId = loginId.replace("&nbsp", "");
			
			if(loginId != null && !"".equals(loginId)){
				//token
				param.clear();
				param.put("token", token);
				result = userDao.selectUid(param);
				
				if(result == null){
					resultJSON.put("Code", 203);
					resultJSON.put("Message", Message.code203);
					return callback + "(" + resultJSON.toString() + ")";
				}else{
					boolean chkTokenToid = tokenToLoginId(token, loginId);
					if(!chkTokenToid){
						resultJSON.put("Code", 205);
						resultJSON.put("Message", Message.code205);
						return callback + "(" + resultJSON.toString() + ")";
					}
				}
			}
			
			pageNum = pageNum.replace("&nbsp", "");
			contentNum = contentNum.replace("&nbsp", "");
			tabIdx = tabIdx.replace("&nbsp", "");
			idx = idx.replace("&nbsp", "");
			
			param.put("type", type);
			param.put("loginId", loginId);
			param.put("tabIdx", tabIdx);
			if(idx != null && !"".equals(idx) && !"null".equals(idx) && StringUtils.isNumeric(idx)){
				param.put("idx", idx);
			}
			if(pageNum != null && !"".equals(pageNum) && !"null".equals(pageNum) && StringUtils.isNumeric(pageNum)){
				param.put("pageNum", pageNum);
			}
			
			if(contentNum != null && !"".equals(contentNum) && !"null".equals(contentNum) && StringUtils.isNumeric(contentNum)){
				param.put("contentNum", contentNum);
			}
			
			if(pageNum != null && !"".equals(pageNum) && !"null".equals(pageNum) && contentNum != null && !"".equals(contentNum) && !"null".equals(contentNum)){
				if(StringUtils.isNumeric(pageNum) && StringUtils.isNumeric(contentNum)){
					int tmpPage = Integer.valueOf(pageNum);
					int tmpContent = Integer.valueOf(contentNum);
					int offset = tmpContent * (tmpPage-1);
					param.put("offset", String.valueOf(offset));
				}else{
					resultJSON.put("Code", 600);
					resultJSON.put("Message", Message.code600);
					return callback + "(" + resultJSON.toString() + ")";
				}
			}
			
			resultList = dataDao.selectVideoList(param);
			if("list".equals(type)){
				result = dataDao.selectVideoListLen(param);
			}else if("one".equals(type)){
				if(idx != null && !"".equals(idx) && !"null".equals(idx) && StringUtils.isNumeric(idx)){
					param.put("shareIdx", idx);
					param.put("shareKind", "GeoVideo");
					shareList = userDao.selectShareUserList(param);
				}else{
					resultJSON.put("Code", 600);
					resultJSON.put("Message", Message.code600);
					return callback + "(" + resultJSON.toString() + ")";
				}
			}
			
			if(resultList != null && resultList.size() != 0) {
				resultJSON.put("Code", 100);
				resultJSON.put("Message", Message.code100);
				resultJSON.put("Data", JSONArray.fromObject(resultList));
				if(result != null){
					resultJSON.put("DataLen", result.get("total_cnt"));
				}
				if(shareList != null && shareList.size() > 0){
					resultJSON.put("shareList", shareList);
				}
			}else {
				resultJSON.put("Code", 200);
				resultJSON.put("Message", Message.code200);
			}
		}else{
			resultJSON.put("Code", 600);
			resultJSON.put("Message", Message.code600);
		}
		
		return callback + "(" + resultJSON.toString() + ")";
	}
	
	@RequestMapping(value = "/cms/saveVideoAll/{token}/{loginId}/{title}/{content}/{projectIdx}/{droneType}", method = RequestMethod.POST, produces="application/json;charset=UTF-8")
	@ResponseBody
	public String saveVideoService(@RequestParam("callback") String callback
			, @PathVariable("token") String token
			, @PathVariable("loginId") String loginId
			, @PathVariable("title") String title
			, @PathVariable("content") String content
			, @PathVariable("projectIdx") String projectIdx
			, @PathVariable("droneType") String droneType
			, Model model, HttpServletRequest request) {
		JSONObject resultJSON = new JSONObject();
		param = new HashMap<String, String>();
		result = new HashMap<String, String>();
		param2 = new HashMap<String, String>();
		String shareType = "";
		List<Object> childResult = new ArrayList<Object>();
		int startSeq = 0;
		int nowSeq = 1;

		//token
		param.clear();
		param.put("token", token);
		
		try {
			result = userDao.selectUid(param);
			
			if(result != null){
				boolean chkTokenToid = tokenToLoginId(token, loginId);
				if(!chkTokenToid){
					resultJSON.put("Code", 205);
					resultJSON.put("Message", Message.code205);
					return callback + "(" + resultJSON.toString() + ")";
				}
				
				if(!(title != null && !"".equals(title) && content != null && !"".equals(content) && (droneType != null && ("&nbsp".equals(droneType) || "Y".equals(droneType))) &&
						projectIdx != null && !"".equals(projectIdx) && StringUtils.isNumeric(projectIdx))){
					resultJSON.put("Code", 600);
					resultJSON.put("Message", Message.code600);
					return callback + "(" + resultJSON.toString() + ")";
				}
				
				//////////////////////////////////////////////////////////////////////////////////////////
				try {
					request.setCharacterEncoding("utf-8");
				} catch (UnsupportedEncodingException e1) {
					e1.printStackTrace();
					resultJSON.put("Code", 300);
					resultJSON.put("Message", Message.code300);
					return callback + "(" + resultJSON.toString() + ")";
				}
				
				title = dataReplaceFun(title);
				content = dataReplaceFun(content);
				droneType = droneType.replaceAll("&nbsp","");
				
				String encode_title;
				String encode_content;
				try {
					encode_title = URLEncoder.encode(title, "EUC-KR");
					encode_content = URLEncoder.encode(content, "EUC-KR");
					
					title = URLDecoder.decode(encode_title, "EUC-KR");
					content = URLDecoder.decode(encode_content, "EUC-KR");
				} catch (UnsupportedEncodingException e) {
					e.printStackTrace();
					resultJSON.put("Code", 300);
					resultJSON.put("Message", Message.code300);
					return callback + "(" + resultJSON.toString() + ")";
				}
				
				param.clear();
				param.put("loginId", loginId);
				param.put("title", title);
				param.put("content", content);
				param.put("projectIdx", projectIdx);
				resultList = dataDao.selectProjectList(param);
				
				result2 = dataDao.selectProjectMaxSeq(param);
				if(result2 != null){
					if(result2.get("max_seq") != null && result2.get("max_seq") != ""){
						startSeq = Integer.valueOf(String.valueOf(result2.get("max_seq")));
					}
				}
				
				if(resultList != null && resultList.size() > 0){
					HashMap<String, String> tmpMap =  (HashMap<String, String>)resultList.get(0);
					if(tmpMap != null){
						shareType = String.valueOf(tmpMap.get("sharetype"));
					}else{
						resultJSON.put("Code", 700);
						resultJSON.put("Message", Message.code300);
						return callback + "(" + resultJSON.toString() + ")";
					}
				}else{
					resultJSON.put("Code", 700);
					resultJSON.put("Message", Message.code300);
					return callback + "(" + resultJSON.toString() + ")";
				}
				
				String uploadType = "GeoVideo";
				String latitude = "0.0";
				String longitude = "0.0";
				String saveFileName = "";
				String saveFileNameOrg = "";
				String startYn = "Y";
				int logKey = 0;
				
				//파일 정보 저장 변수
				List<Map<String, String>> files = new ArrayList<Map<String, String>>();
				ArrayList<String> filesXml = new ArrayList<String>();
				ArrayList<FileItem> fileItemList = new ArrayList<FileItem>();
				String saveUserPath = request.getSession().getServletContext().getRealPath("/")+ "upload";
				File saveUserPathDir = new File(saveUserPath);
			    if(!saveUserPathDir.exists()) saveUserPathDir.mkdir();
				
				//파일 업로드
				boolean isMultipart = ServletFileUpload.isMultipartContent(request); // 멀티파트인지 체크
				File tempDir = null;
				File uploadDir = null;
				int fileIndex = 1;
				int parentIndex = 0;
				int childIndex = 0;
				String insertKey = "";

				System.out.println("isMultipart : "+isMultipart);
				
				DefaultTransactionDefinition def = new DefaultTransactionDefinition();
				def.setPropagationBehavior(TransactionDefinition.PROPAGATION_REQUIRED);
				// construct an appropriate transaction manager
				DataSourceTransactionManager txManager = new DataSourceTransactionManager(dataSource);
				TransactionStatus sts = txManager.getTransaction(def);
				
				try {
					if(isMultipart) {
						int uploadMaxSize = 2*1024*1024*1024; //1024MB = 1GB
						tempDir = new File(saveUserPath+"/"+"tmp");
						uploadDir = new File(saveUserPath);
						 
						if(!tempDir.exists()) tempDir.mkdir();
						if(!uploadDir.exists()) uploadDir.mkdir();
						
						uploadDir = new File(saveUserPath+"/"+uploadType);
						if(!uploadDir.exists()) uploadDir.mkdir();
						
						param.clear();
						param.put("loginId", loginId);
						param.put("title", title);
						param.put("content", content);
						param.put("latitude", latitude);
						param.put("longitude", longitude);
						param.put("projectidx", projectIdx);
						param.put("sharetype", shareType);
						
						DiskFileItemFactory factory = new DiskFileItemFactory(uploadMaxSize, tempDir);
						ServletFileUpload upload = new ServletFileUpload(factory);
						 
						upload.setSizeMax(uploadMaxSize);
						List items = upload.parseRequest(request);
						Iterator iter = items.iterator();
						
						Map<String,String> filesMap = new HashMap<String, String>();
						FileItem item = null;
						String fileName = "";
						String changeFileName = "";
						int gpxFileIndex = 1;
						File uploadFile;
						String oldSubfix = "";
						File tmpGpxFilePathDir = new File(uploadDir+File.separator+ loginId +"_"+ logKey);///
						if(!tmpGpxFilePathDir.exists()) tmpGpxFilePathDir.mkdir();////
						String tmpGpxFilePath = "";
						String tmpGpxFileName = "";
						String prefix = "";
						String suffix = "";
						String tmpPathStr = "";
						HashMap<String, Object> childParam = new HashMap<String, Object>();
						
						while(iter.hasNext()) {
							filesMap = new HashMap<String, String>();
							childResult = new ArrayList<Object>();
							childParam = new HashMap<String, Object>();
							gpxFileIndex = 1;
							uploadFile = null;
							changeFileName = "";
							tmpGpxFilePath = "";
							tmpGpxFileName = "";
							prefix = "";
							suffix = "";
							oldSubfix = "";
							saveFileName = "";
							childIndex = 0;
							tmpPathStr = "";
							nowSeq = 1;
							
							item = (FileItem)iter.next();
							if(!item.isFormField()) {
								//file upload start
								if(startYn != null && "Y".equals(startYn)){
									//update token time
									param.put("uid", String.valueOf(result.get("uid")));
									resultIntegerValue = userDao.updateTokenTime(param);
								}
								
								fileName = item.getName();
								
								if(fileName != null && !"".equals(fileName)){
									fileItemList.add(item);
									oldSubfix = fileName.substring(fileName.lastIndexOf("."));
									
									if(fileName.indexOf(".gpx") > 0){
										tmpGpxFilePath = tmpGpxFilePathDir + File.separator + fileName;
										tmpGpxFileName = tmpGpxFilePath.substring(0, tmpGpxFilePath.lastIndexOf("."))+"_ogg.gpx";
										prefix = tmpGpxFilePath.substring(0, tmpGpxFilePath.lastIndexOf("."));
										uploadFile  = new File(tmpGpxFilePath);
										
										while((uploadFile = new File(tmpGpxFileName)).exists()) {
											suffix = "_ogg.gpx";
											tmpGpxFileName = prefix+"("+gpxFileIndex+")"+suffix;
											gpxFileIndex++;
											uploadFile = new File(tmpGpxFileName);
										}
										filesMap.put("file", tmpGpxFileName);
										filesMap.put("idx", null);
										files.add(filesMap);
										filesXml.add(tmpGpxFileName);
									}else{
										prefix = fileName.substring(0, fileName.lastIndexOf("."));
										changeFileName = prefix +  "_ogg.ogg";
										param2.clear();
										param2.put("contentKind", "GeoVideo");
										param2.put("fileName", changeFileName);
										childResult = dataDao.selectContentChildList(param2);
										while(childResult != null && childResult.size() > 0) {
											suffix = "_ogg.ogg";
											changeFileName = prefix+"("+fileIndex+")"+suffix;
											fileIndex++;
											param2.put("fileName", changeFileName);
											childResult = dataDao.selectContentChildList(param2);
										}
										
										saveFileName = changeFileName.substring(0, changeFileName.lastIndexOf("_ogg"));
										
										//data save
										title = title.replaceAll("&sbsp","/");
										content = content.replaceAll("&sbsp","/");

										//data save end
										if(startYn != null && "Y".equals(startYn)){
											saveFileNameOrg = saveFileName;
											startYn = "N";
											param.put("thumbnail", saveFileName+"_thumb.jpg");
											param.put("filename", saveFileName+"_ogg.ogg");
											param.put("originname", saveFileName+ oldSubfix);
											
											nowSeq += startSeq;
											param.put("seqnum", String.valueOf(nowSeq));
											param.put("dronetype", droneType);
											
											
											resultIntegerValue = dataDao.insertVideo(param);
											if(resultIntegerValue > 0){
												if(param.get("idx") != null && String.valueOf(param.get("idx")) != ""){
													parentIndex = Integer.valueOf(String.valueOf(param.get("idx")));
													insertKey = String.valueOf(param.get("idx"));
												}
											}
										}
										
										if(parentIndex > 0){
											childParam.put("parentIdx", parentIndex);
											childParam.put("fileName", changeFileName);
											childParam.put("originName", saveFileName + oldSubfix);
											childParam.put("thumbnail", saveFileName + "_thumb.jpg");
											resultIntegerValue = dataDao.insertChildContent(childParam);
											if(resultIntegerValue > 0){
												if(String.valueOf(childParam.get("idx")) != null && String.valueOf(childParam.get("idx")) != ""){
													childIndex = Integer.valueOf(String.valueOf(childParam.get("idx")));
												}
												if(resultIntegerValue > 1 && param != null) {
													if(shareType != null && "2".equals(shareType)){
														param.put("shareIdx", String.valueOf(parentIndex));
														param.put("shareKind", "GeoVideo");
														resultIntegerValue = userDao.insertShareFormProject(param);
													}
												}
											}
										}else{
											resultIntegerValue = 0;
										}
										
										tmpPathStr = tmpGpxFilePathDir+File.separator+ saveFileName + oldSubfix;
										filesMap.put("file", tmpPathStr);
										filesMap.put("idx", String.valueOf(childIndex));
										files.add(filesMap);
									}
									
								}//file name not null
							}
						}//while end
						
					}else{
						resultJSON.put("Code", 400);
						resultJSON.put("Message", Message.code400);
						return callback + "(" + resultJSON.toString() + ")";
					}
				} catch (Exception e) {
					txManager.rollback(sts);
					e.printStackTrace();
					
					resultJSON.put("Code", 400);
					resultJSON.put("Message", Message.code400);
					return callback + "(" + resultJSON.toString() + ")";
				}
				txManager.commit(sts);
				
				param2.clear();
				param2.put("loginId", loginId);
				param2.put("contentIdx", insertKey);
				param2.put("contentType", "GeoVideo");
				param2.put("status", "PROGRESS");
				int resInt = dataDao.insertLog(param2);
				
				if(resInt > 0){
					if(param2 != null && !"".equals(param2) && param2.get("idx") != null && !"".equals(param2.get("idx"))){
						logKey = Integer.valueOf(String.valueOf(param2.get("idx")));
						if(logKey <= 0){
							resultJSON.put("Code", 300);
							resultJSON.put("Message", Message.code300);
							return callback + "(" + resultJSON.toString() + ")";
						}
						videoSaveStart(loginId, String.valueOf(logKey), saveFileNameOrg, String.valueOf(parentIndex), files, filesXml, fileItemList, saveUserPath, "videoFile");
					}else{
						resultJSON.put("Code", 300);
						resultJSON.put("Message", Message.code300);
						return callback + "(" + resultJSON.toString() + ")";
					}
				}else{
					resultJSON.put("Code", 300);
					resultJSON.put("Message", Message.code300);
					return callback + "(" + resultJSON.toString() + ")";
				}
				
				if(resultIntegerValue > 0) {
					resultJSON.put("Code", 100);
					resultJSON.put("Message", Message.code100);
					resultJSON.put("logKey", String.valueOf(logKey));
				}else{
					resultJSON.put("Code", 300);
					resultJSON.put("Message", Message.code300);
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
	
	@RequestMapping(value = "/cms/updateVideo/{token}/{loginId}/{idx}/{title}/{content}/{shareType}/{addShareUser}/{removeShareUser}/{xmlData}/{editYes}/{editNo}", method = RequestMethod.POST, produces="application/json;charset=UTF-8")
	@ResponseBody
	public String updateVideoService(@RequestParam("callback") String callback
			, @PathVariable("token") String token
			, @PathVariable("loginId") String loginId
			, @PathVariable("idx") String idx
			, @PathVariable("title") String title
			, @PathVariable("content") String content
			, @PathVariable("shareType") String shareType
			, @PathVariable("addShareUser") String addShareUser
			, @PathVariable("removeShareUser") String removeShareUser
			, @PathVariable("xmlData") String xmlData
			, @PathVariable("editYes") String editYes
			, @PathVariable("editNo") String editNo
			, Model model, HttpServletRequest request) {
		JSONObject resultJSON = new JSONObject();
		param = new HashMap<String, String>();
		result = new HashMap<String, String>();

		//token
		param.clear();
		param.put("token", token);
		
		try {
			result = userDao.selectUid(param);
			
			if(result != null){
				boolean chkTokenToid = tokenToLoginId(token, loginId);
				if(!chkTokenToid){
					resultJSON.put("Code", 205);
					resultJSON.put("Message", Message.code205);
					return callback + "(" + resultJSON.toString() + ")";
					
				}
				
				//update token time
				param.put("uid", String.valueOf(result.get("uid")));
				resultIntegerValue = userDao.updateTokenTime(param);
				
				title = dataReplaceFun(title);
				content = dataReplaceFun(content);
				
				addShareUser = addShareUser.replace("&nbsp", "");
				removeShareUser = removeShareUser.replace("&nbsp", "");
				if(xmlData != null && !"".equals(xmlData) && !"null".equals(xmlData)){
					xmlData = xmlData.replaceAll("&nbsp","").replaceAll("&sbsp","/").replaceAll("&mbsp", "?").replaceAll("&pbsp", "#").replace("&obsp", ".");
				}
				editYes = editYes.replace("&nbsp", "");
				editNo = editNo.replace("&nbsp", "");
				
				if(!(title != null && !"".equals(title) && content != null && !"".equals(content) && 
						idx != null && !"".equals(idx) && StringUtils.isNumeric(idx) &&
								shareType != null && !"".equals(shareType) && checkContentListType(shareType,"shareType"))){
					resultJSON.put("Code", 600);
					resultJSON.put("Message", Message.code600);
					return callback + "(" + resultJSON.toString() + ")";
				}
				
				param.clear();
				param.put("loginId", loginId);
				param.put("idx", idx);
				param.put("title", title);
				param.put("content", content);
				param.put("shareType", shareType);
				param.put("xmlData", xmlData);
				resultIntegerValue = dataDao.updateVideo(param);
				
				if(resultIntegerValue == 1) {
					if(shareType != null && !"".equals(shareType) && !"null".equals(shareType) && checkContentListType(shareType, "shareType")){
						HashMap<String, Object> tmpParam = new HashMap<String, Object>();
						tmpParam.put("shareIdx", idx);
						tmpParam.put("shareKind", "GeoVideo");
						
						if("2".equals(shareType)){
							if(addShareUser != null && !"".equals(addShareUser) && !"null".equals(addShareUser) && checkListIsNumber(addShareUser)){
								String[] shareTList = addShareUser.split(",");
								tmpParam.put("shareTList", shareTList);
								resultIntegerValue = userDao.insertShare(tmpParam);
							}
							if(removeShareUser != null && !"".equals(removeShareUser) && !"null".equals(removeShareUser) && checkListIsNumber(removeShareUser)){
								String[] shareTList = removeShareUser.split(",");
								tmpParam.put("shareTList", shareTList);
								resultIntegerValue = userDao.deleteShare(tmpParam);
							}
							if(editYes != null && !"".equals(editYes) && !"null".equals(editYes) && checkListIsNumber(editYes)){
								String[] editList = editYes.split(",");
								tmpParam.put("editType", "Y");
								tmpParam.put("editList", editList);
								resultIntegerValue = userDao.updateShareEdit(tmpParam);
							}
							if(editNo != null && !"".equals(editNo) && !"null".equals(editNo) && checkListIsNumber(editNo)){
								String[] editList = editNo.split(",");
								tmpParam.put("editType", "N");
								tmpParam.put("editList", editList);
								resultIntegerValue = userDao.updateShareEdit(tmpParam);
							}
						}else{
							resultIntegerValue = userDao.deleteShare(tmpParam);
						}
						resultJSON.put("Code", 100);
						resultJSON.put("Message", Message.code100);
					}
				}else{
					resultJSON.put("Code", 300);
					resultJSON.put("Message", Message.code300);
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
	
	@RequestMapping(value = "/cms/getProjectList/{token}/{loginId}/{orderIdx}/{shareEdit}", method = RequestMethod.GET, produces="application/json;charset=UTF-8")
	@ResponseBody
	public String getProjectGroupService(@RequestParam("callback") String callback
			, @PathVariable("token") String token
			, @PathVariable("loginId") String loginId
			, @PathVariable("orderIdx") String orderIdx
			, @PathVariable("shareEdit") String shareEdit
			, Model model, HttpServletRequest request) {
		JSONObject resultJSON = new JSONObject();
		
		param = new HashMap<String, String>();
		result = new HashMap<String, String>();
		resultList = new ArrayList<Object>();
		
		//token
		param.clear();
		param.put("token", token);
		
		try {
			result = userDao.selectUid(param);
			
			if(result != null){
				boolean chkTokenToid = tokenToLoginId(token, loginId);
				if(!chkTokenToid){
					resultJSON.put("Code", 205);
					resultJSON.put("Message", Message.code205);
					return callback + "(" + resultJSON.toString() + ")";
				}
				
				orderIdx = orderIdx.replace("&nbsp", "");
				shareEdit = shareEdit.replace("&nbsp", "");
				
				param.put("loginId", loginId);
				if(orderIdx != null && !"".equals(orderIdx) && !"null".equals(orderIdx) && StringUtils.isNumeric(orderIdx)){
					param.put("orderIdx", orderIdx);
				}
				param.put("shareEdit", shareEdit);
				resultList = dataDao.selectProjectList(param);
				
				if(resultList != null && resultList.size() != 0) {
					resultJSON.put("Code", 100);
					resultJSON.put("Message", Message.code100);
					resultJSON.put("Data", JSONArray.fromObject(resultList));
				}else{
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
	
	@RequestMapping(value = "/cms/getProjectContent/{token}/{loginId}/{type}/{projectIdx}/{pageNum}/{contentNum}", method = RequestMethod.GET, produces="application/json;charset=UTF-8")
	@ResponseBody
	public String getProjectService(@RequestParam("callback") String callback
			, @PathVariable("token") String token
			, @PathVariable("loginId") String loginId
			, @PathVariable("projectIdx") String projectIdx
			, @PathVariable("type") String type
			, @PathVariable("pageNum") String pageNum
			, @PathVariable("contentNum") String contentNum
			, Model model, HttpServletRequest request) {
		JSONObject resultJSON = new JSONObject();
		
		param = new HashMap<String, String>();
		result = new HashMap<String, String>();
		
		//token
		param.clear();
		param.put("token", token);
		
		try {
			result = userDao.selectUid(param);
			
//			if(result != null){
//				boolean chkTokenToid = tokenToLoginId(token, loginId);
//				if(!chkTokenToid){
//					resultJSON.put("Code", 205);
//					resultJSON.put("Message", Message.code205);
//					return callback + "(" + resultJSON.toString() + ")";
//				}
				
				pageNum = pageNum.replace("&nbsp", "");
				contentNum = contentNum.replace("&nbsp", "");
				
				param.put("loginId", loginId);
				param.put("getProject", "Y");
				param.put("type", type);
				
				if(projectIdx == null || "".equals(projectIdx) || "null".equals(projectIdx) || !(StringUtils.isNumeric(projectIdx) || checkListIsNumber(projectIdx))){
					resultJSON.put("Code", 600);
					resultJSON.put("Message", Message.code600);
					return callback + "(" + resultJSON.toString() + ")";
				}
				
				if(pageNum != null && !"".equals(pageNum) && !"null".equals(pageNum) && StringUtils.isNumeric(pageNum)){
					param.put("pageNum", pageNum);
				}
				
				if(contentNum != null && !"".equals(contentNum) && !"null".equals(contentNum) && StringUtils.isNumeric(contentNum)){
					param.put("contentNum", contentNum);
				}
				
				if(type != null && checkContentListType(type, "projectType")){
					if("marker".equals(type) && projectIdx != null && !"".equals(projectIdx) && !"null".equals(projectIdx)){
						if(checkListIsNumber(projectIdx)){
							String[] projectIdxList = projectIdx.split(",");
							List<Object> resultList2 = new ArrayList<Object>();
							
							if(projectIdxList != null && projectIdxList.length > 0){
								for(int i=0; i<projectIdxList.length;i++){
									param.put("projectIdx", projectIdxList[i]);
									resultList = dataDao.selectProjectContentList(param);
									if(resultList != null && resultList.size()>0){
										resultList2.addAll(resultList);
									}
								}
							}
							resultList = resultList2;
						}
					}else {
						if(pageNum != null && !"".equals(pageNum) && !"null".equals(pageNum) && contentNum != null && !"".equals(contentNum) && !"null".equals(contentNum)){
							if(StringUtils.isNumeric(pageNum) && StringUtils.isNumeric(contentNum)){
								int tmpPage = Integer.valueOf(pageNum);
								int tmpContent = Integer.valueOf(contentNum);
								int offset = tmpContent * (tmpPage-1);
								param.put("offset", String.valueOf(offset));
							}else{
								resultJSON.put("Code", 600);
								resultJSON.put("Message", Message.code600);
								return callback + "(" + resultJSON.toString() + ")";
							}
						}
						
						if(projectIdx != null && !"".equals(projectIdx) && !"null".equals(projectIdx) && StringUtils.isNumeric(projectIdx)){
							param.put("projectIdx", projectIdx);
							resultList = dataDao.selectProjectContentList(param);
							result = dataDao.selectProjectContentListLen(param);
						}else{
							resultJSON.put("Code", 600);
							resultJSON.put("Message", Message.code600);
							return callback + "(" + resultJSON.toString() + ")";
						}
					}
					
					if(resultList != null && resultList.size() != 0) {
						resultJSON.put("Code", 100);
						resultJSON.put("Message", Message.code100);
						resultJSON.put("Data", JSONArray.fromObject(resultList));
						resultJSON.put("DataLen", result.get("total_cnt"));
					}else{
						resultJSON.put("Code", 200);
						resultJSON.put("Message", Message.code200);
					}
				}else{
					resultJSON.put("Code", 600);
					resultJSON.put("Message", Message.code600);
				}
//			}else{
//				resultJSON.put("Code", 203);
//				resultJSON.put("Message", Message.code203);
//			}
		} catch (Exception e) {
			e.printStackTrace();
			resultJSON.put("Code", 800);
			resultJSON.put("Message", Message.code800);
		}
		
		return callback + "(" + resultJSON.toString() + ")";
	}
	
	@RequestMapping(value = "/cms/saveProject/{token}/{loginId}/{projectName}/{shareType}/{shareUser}/{projectEditYes}", method = RequestMethod.POST, produces="application/json;charset=UTF-8")
	@ResponseBody
	public String saveProjectService(@RequestParam("callback") String callback
			, @PathVariable("token") String token
			, @PathVariable("loginId") String loginId
			, @PathVariable("projectName") String projectName
			, @PathVariable("shareType") String shareType
			, @PathVariable("shareUser") String shareUser
			, @PathVariable("projectEditYes") String projectEditYes
			, Model model, HttpServletRequest request, HttpServletResponse response) {
		response .setHeader("Access-Control-Allow-Methods" , "POST, GET, OPTIONS, DELETE" );
		response.setHeader( "Access-Control-Max-Age" , "3600" );
		response.setHeader( "Access-Control-Allow-Headers" , "x-requested-with" );
		response.setHeader( "Access-Control-Allow-Origin" , "*" );

		
		JSONObject resultJSON = new JSONObject();
		param = new HashMap<String, String>();
		result = new HashMap<String, String>();
		String saveIdx = "";
		
		//token
		param.clear();
		param.put("token", token);
		
		try {
			result = userDao.selectUid(param);
			
			if(result != null){
				boolean chkTokenToid = tokenToLoginId(token, loginId);
				if(!chkTokenToid){
					resultJSON.put("Code", 205);
					resultJSON.put("Message", Message.code205);
					return callback + "(" + resultJSON.toString() + ")";
				}
				
				if(projectName == null || projectName == "" || projectName == "null"){
					resultJSON.put("Code", 600);
					resultJSON.put("Message", Message.code600);
				}
				
				if(shareType != null && !"".equals(shareType) && !"null".equals(shareType) && checkContentListType(shareType, "shareType")){
					//update token time
					param.put("uid", String.valueOf(result.get("uid")));
					resultIntegerValue = userDao.updateTokenTime(param);
					
					projectName = dataReplaceFun(projectName);
					shareUser = shareUser.replace("&nbsp", "");
					projectEditYes = projectEditYes.replace("&nbsp", "");
					
					param.clear();
					param.put("loginId", loginId);
					param.put("projectName", projectName);
					param.put("shareType", shareType);
					resultIntegerValue = dataDao.insertProject(param);
					
					if(shareType != null && "2".equals(shareType) && shareUser != null && !"".equals(shareUser) && !"null".equals(shareUser)){
						if(checkListIsNumber(shareUser)){
							HashMap<String, Object> tmpParam = new HashMap<String, Object>();
							String[] shareTList = shareUser.split(",");
							tmpParam.put("shareTList", shareTList);
							tmpParam.put("shareIdx", param.get("idx"));
							tmpParam.put("shareKind", "GeoProject");
							resultIntegerValue = userDao.insertShare(tmpParam);
							
							if(projectEditYes != null && !"".equals(projectEditYes) && !"null".equals(projectEditYes) && checkListIsNumber(projectEditYes)){
								String[] editList = projectEditYes.split(",");
								tmpParam.put("editType", "Y");
								tmpParam.put("editList", editList);
								resultIntegerValue = userDao.updateShareEdit(tmpParam);
							}else{
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
					
					if(param != null && param.get("idx") != null){
						saveIdx = String.valueOf(param.get("idx"));
					}
					
					if(resultIntegerValue > 0) {
						resultJSON.put("Code", 100);
						resultJSON.put("Message", Message.code100);
						resultJSON.put("Data", saveIdx);
					}else{
						resultJSON.put("Code", 300);
						resultJSON.put("Message", Message.code300);
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
	
	@RequestMapping(value = "/cms/updateProject/{token}/{loginId}/{projectIdx}/{projectName}/{shareType}/{shareAddUser}/{shareRemoveUser}/{projectEditYes}/{projectEditNo}", method = RequestMethod.POST, produces="application/json;charset=UTF-8")
	@ResponseBody
	public String updateProjectService(@RequestParam("callback") String callback
			, @PathVariable("token") String token
			, @PathVariable("loginId") String loginId
			, @PathVariable("projectIdx") String projectIdx
			, @PathVariable("projectName") String projectName
			, @PathVariable("shareType") String shareType
			, @PathVariable("shareAddUser") String shareAddUser
			, @PathVariable("shareRemoveUser") String shareRemoveUser
			, @PathVariable("projectEditYes") String projectEditYes
			, @PathVariable("projectEditNo") String projectEditNo
			, Model model, HttpServletRequest request, HttpServletResponse response) {
		response.setHeader("Access-Control-Allow-Methods", "POST, GET, OPTIONS, DELETE");
        response.setHeader("Access-Control-Max-Age", "3600");
        response.setHeader("Access-Control-Allow-Headers", "x-requested-with");
        response.setHeader("Access-Control-Allow-Origin", "*");


		JSONObject resultJSON = new JSONObject();
		param = new HashMap<String, String>();
		result = new HashMap<String, String>();
		
		//token
		param.clear();
		param.put("token", token);
		
		try {
			result = userDao.selectUid(param);
			
			if(result != null){
				boolean chkTokenToid = tokenToLoginId(token, loginId);
				if(!chkTokenToid){
					resultJSON.put("Code", 205);
					resultJSON.put("Message", Message.code205);
					return callback + "(" + resultJSON.toString() + ")";
				}
				
				if(projectIdx == null || projectIdx == "" || projectIdx == "null" || !StringUtils.isNumeric(projectIdx)){
					resultJSON.put("Code", 600);
					resultJSON.put("Message", Message.code600);
					return callback + "(" + resultJSON.toString() + ")";
				}
				
					//update token time
					param.put("uid", String.valueOf(result.get("uid")));
					resultIntegerValue = userDao.updateTokenTime(param);
					
					projectName = dataReplaceFun(projectName);
					shareAddUser = shareAddUser.replace("&nbsp", "");
					shareRemoveUser = shareRemoveUser.replace("&nbsp", "");
					projectEditYes = projectEditYes.replace("&nbsp", "");
					projectEditNo = projectEditNo.replace("&nbsp", "");
					shareType = shareType.replace("&nbsp", "");
					
					param.clear();
					param.put("loginId", loginId);
					if(projectName != null && !"".equals(projectName)){
						param.put("projectName", projectName);
					}
					
					if(shareType != null && !"".equals(shareType) && !"null".equals(shareType)){
						if(checkContentListType(shareType, "shareType")){
							param.put("shareType", shareType);
						}else{
							resultJSON.put("Code", 600);
							resultJSON.put("Message", Message.code600);
							return callback + "(" + resultJSON.toString() + ")";
						}
					}
					param.put("idx", projectIdx);
					resultIntegerValue = dataDao.updateProject(param);
					
					if(resultIntegerValue == 1 && shareType != null && !"".equals(shareType) && !"null".equals(shareType) && checkContentListType(shareType, "shareType")){
						HashMap<String, Object> tmpParam = new HashMap<String, Object>();
						tmpParam.put("shareIdx", projectIdx);
						tmpParam.put("shareKind", "GeoProject");
						
						if("2".equals(shareType)){
							if(shareAddUser != null && !"".equals(shareAddUser) && !"null".equals(shareAddUser) && checkListIsNumber(shareAddUser)){
								String[] shareTList = shareAddUser.split(",");
								tmpParam.put("shareTList", shareTList);
								resultIntegerValue += userDao.insertShare(tmpParam);
							}
							if(shareRemoveUser != null && !"".equals(shareRemoveUser) && !"null".equals(shareRemoveUser) && checkListIsNumber(shareRemoveUser)){
								String[] shareTList = shareRemoveUser.split(",");
								tmpParam.put("shareTList", shareTList);
								resultIntegerValue += userDao.deleteShare(tmpParam);
							}
							
							if(projectEditYes != null && !"".equals(projectEditYes) && !"null".equals(projectEditYes) && checkListIsNumber(projectEditYes)){
								String[] editList = projectEditYes.split(",");
								tmpParam.put("editType", "Y");
								tmpParam.put("editList", editList);
								resultIntegerValue += userDao.updateShareEdit(tmpParam);
							}
							
							if(projectEditNo != null && !"".equals(projectEditNo) && !"null".equals(projectEditNo) && checkListIsNumber(projectEditNo)){
								String[] editList = projectEditNo.split(",");
								tmpParam.put("editType", "N");
								tmpParam.put("editList", editList);
								resultIntegerValue += userDao.updateShareEdit(tmpParam);
							}
						}else{
							resultIntegerValue += userDao.deleteShare(tmpParam);
						}
						
						//image 
						HashMap<String, String> imgTmp = new HashMap<String, String>();
						HashMap<String, Object> imgTmp2 = new HashMap<String, Object>();
						imgTmp.put("projectIdx", projectIdx);
						resultList = dataDao.selectProjectContentList(imgTmp);
						
						if(resultList != null && resultList.size()>0){
							for(int a=0;a<resultList.size();a++){
								HashMap<String, String> tmpMap = (HashMap<String, String>)resultList.get(a);
								if(tmpMap != null){
									//�대�吏�怨듭� ��� 蹂�꼍
									tmpMap.put("moveContent", String.valueOf(tmpMap.get("idx")));
									tmpMap.put("shareType", shareType);
									resultIntegerValue += dataDao.updateImageMove(tmpMap);
									
									//怨듭� ��� ���
									imgTmp2 = new HashMap<String, Object>();
									imgTmp2.put("shareIdx", String.valueOf(tmpMap.get("idx")));
									imgTmp2.put("shareKind", tmpMap.get("datakind"));
									resultIntegerValue += userDao.deleteShare(imgTmp2);
									
									if("2".equals(shareType)){
										//怨듭� ��� 異��
										imgTmp.put("shareIdx", String.valueOf(tmpMap.get("idx")));
										imgTmp.put("shareKind", tmpMap.get("datakind"));
										resultIntegerValue += userDao.insertShareFormProject(imgTmp);
									}
									
								}
							}
						}
					}
					if(resultIntegerValue > 0) {
						resultJSON.put("Code", 100);
						resultJSON.put("Message", Message.code100);
					}else{
						resultJSON.put("Code", 300);
						resultJSON.put("Message", Message.code300);
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
	
	@RequestMapping(value = "/cms/moveProject/{token}/{loginId}/{moveProISIdx}/{moveContentArr}", method = RequestMethod.POST, produces="application/json;charset=UTF-8")
	@ResponseBody
	public String moveProjectService(@RequestParam("callback") String callback
			, @PathVariable("token") String token
			, @PathVariable("loginId") String loginId
			, @PathVariable("moveProISIdx") String moveProISIdx
			, @PathVariable("moveContentArr") String moveContentArr
			, Model model, HttpServletRequest request) {
		JSONObject resultJSON = new JSONObject();
		param = new HashMap<String, String>();
		result = new HashMap<String, String>();
		
		//token
		param.clear();
		param.put("token", token);
		
		try {
			result = userDao.selectUid(param);
			
			if(result != null){
				boolean chkTokenToid = tokenToLoginId(token, loginId);
				if(!chkTokenToid){
					resultJSON.put("Code", 205);
					resultJSON.put("Message", Message.code205);
					return callback + "(" + resultJSON.toString() + ")";
				}
				
				//update token time
				param.put("uid", String.valueOf(result.get("uid")));
				resultIntegerValue = userDao.updateTokenTime(param);
				
				if(moveProISIdx != null && !"".equals(moveProISIdx) && !"null".equals(moveProISIdx) && StringUtils.isNumeric(moveProISIdx) &&
						moveContentArr != null){
					
					param2 = new HashMap<String, String>();
					param2.put("loginId", loginId);
					param2.put("projectIdx", moveProISIdx);
					param2.put("shareEdit", "Y");
					List<Object> resultList2 = dataDao.selectProjectList(param2);
					
					if(resultList2 != null && resultList2.size() == 1){
						Map<String, Object> tmpParam2 = (Map<String,Object>)resultList2.get(0);
						String moveProISShare = "";
						if(tmpParam2 != null){
							if(tmpParam2.get("sharetype") != null && !"".equals(tmpParam2.get("sharetype"))){
								moveProISShare = String.valueOf(tmpParam2.get("sharetype"));
							}
						}

						if(moveProISShare != null && !"".equals(moveProISShare) && !"null".equals(moveProISShare) && checkContentListType(moveProISShare, "shareType")){
							HashMap<String, Object> tmpParam = new HashMap<String, Object>();
							
							String[] moveContentList = moveContentArr.split(",");
							if(moveContentList != null && moveContentList.length > 0){
								param.clear();
								param.put("shareType", moveProISShare);
								param.put("projectIdx", moveProISIdx);
								
								boolean resCheck = true;
								for(int i=0; i<moveContentList.length; i++){
									if(moveContentList[i] != null){
										String[] tmpMv = moveContentList[i].split("_");
										if(tmpMv != null && tmpMv.length == 2 && tmpMv[0] != null && ("GeoPhoto".equals(tmpMv[0]) || "GeoVideo".equals(tmpMv[0])) && tmpMv[1] != null && tmpMv[1] != "" && StringUtils.isNumeric(tmpMv[1]) ){
											if("GeoPhoto".equals(tmpMv[0])){
												HashMap<String, String> param3 = new HashMap<String, String>();
												param3.put("loginId", loginId);
												param3.put("idx", tmpMv[1]);
												param3.put("myContent", "Y");
												List<Object> resultList3 = dataDao.selectImageList(param3);
												if(!(resultList3 != null && resultList3.size() > 0)){
													resCheck = false;
												}
											}else if("GeoVideo".equals(tmpMv[0])){
												HashMap<String, String> param3 = new HashMap<String, String>();
												param3.put("loginId", loginId);
												param3.put("idx", tmpMv[1]);
												param3.put("myContent", "Y");
												List<Object> resultList3 = dataDao.selectVideoList(param3);
												if(!(resultList3 != null && resultList3.size() > 0)){
													resCheck = false;
												}
											}
										}else{
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
								
								if(resCheck){
									int startSeq = 1;
									int nowSeq = 1;
									result2 = dataDao.selectProjectMaxSeq(param);
									if(result2 != null){
										if(result2.get("max_seq") != null && result2.get("max_seq") != ""){
											startSeq = Integer.valueOf(String.valueOf(result2.get("max_seq")));
										}
									}
									
									for(int i=0; i<moveContentList.length; i++){
										if(moveContentList[i] != null){
											nowSeq = startSeq + 1 +i;
											String[] tmpMv = moveContentList[i].split("_");
											if(tmpMv[0] != null && ("GeoPhoto".equals(tmpMv[0]) || "GeoVideo".equals(tmpMv[0])) && tmpMv[1] != null && tmpMv[1] != "" && StringUtils.isNumeric(tmpMv[1]) ){
												if("GeoPhoto".equals(tmpMv[0])){
													param.put("moveContent", tmpMv[1]);
													param.put("nowSeq", String.valueOf(nowSeq));
													resultIntegerValue = dataDao.updateImageMove(param);
													
													//share user delete
													tmpParam = new HashMap<String, Object>();
													tmpParam.put("shareIdx", tmpMv[1]);
													tmpParam.put("shareKind","GeoPhoto");
													resultIntegerValue += userDao.deleteShare(tmpParam);
													
													if("2".equals(moveProISShare)){
														//share user add
														param.put("shareIdx", String.valueOf(tmpMv[1]));
														param.put("shareKind", "GeoPhoto");
														resultIntegerValue += userDao.insertShareFormProject(param);
													}
												}else if("GeoVideo".equals(tmpMv[0])){
													param.put("moveContent", tmpMv[1]);
													param.put("nowSeq", String.valueOf(nowSeq));
													resultIntegerValue = dataDao.updateVideoMove(param);
													
													//share user delete
													tmpParam = new HashMap<String, Object>();
													tmpParam.put("shareIdx", tmpMv[1]);
													tmpParam.put("shareKind","GeoVideo");
													resultIntegerValue += userDao.deleteShare(tmpParam);
													
													if("2".equals(moveProISShare)){
														//share user add
														param.put("shareIdx", String.valueOf(tmpMv[1]));
														param.put("shareKind", "GeoVideo");
														resultIntegerValue += userDao.insertShareFormProject(param);
													}
												}
											}else{
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
								}else{
									resultJSON.put("Code", 700);
									resultJSON.put("Message", Message.code700);
									return callback + "(" + resultJSON.toString() + ")";
								}
								
								if(resultIntegerValue > 0) {
									resultJSON.put("Code", 100);
									resultJSON.put("Message", Message.code100);
								}else{
									resultJSON.put("Code", 300);
									resultJSON.put("Message", Message.code300);
								}
							}else{
								resultJSON.put("Code", 600);
								resultJSON.put("Message", Message.code600);
							}
						}else{
							resultJSON.put("Code", 600);
							resultJSON.put("Message", Message.code600);
						}
					}else{
						resultJSON.put("Code", 600);
						resultJSON.put("Message", Message.code600);
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
	
	@RequestMapping(value = "/cms/removeProject/{token}/{loginId}/{projectIdx}", method = RequestMethod.POST, produces="application/json;charset=UTF-8")
	@ResponseBody
	public String rmoveProjectService(@RequestParam("callback") String callback
			, @PathVariable("token") String token
			, @PathVariable("loginId") String loginId
			, @PathVariable("projectIdx") String projectIdx
			, Model model, HttpServletRequest request, HttpServletResponse response) {
		response.setHeader("Access-Control-Allow-Methods", "POST, GET, OPTIONS, DELETE");
        response.setHeader("Access-Control-Max-Age", "3600");
        response.setHeader("Access-Control-Allow-Headers", "x-requested-with");
        response.setHeader("Access-Control-Allow-Origin", "*");
        
		JSONObject resultJSON = new JSONObject();
		param = new HashMap<String, String>();
		result = new HashMap<String, String>();
		
		//token
		param.clear();
		param.put("token", token);
		
		try {
			result = userDao.selectUid(param);
			
			if(result != null){
				boolean chkTokenToid = tokenToLoginId(token, loginId);
				if(!chkTokenToid){
					resultJSON.put("Code", 205);
					resultJSON.put("Message", Message.code205);
					return callback + "(" + resultJSON.toString() + ")";
				}
				
				if(projectIdx != null && !"".equals(projectIdx) && !"null".equals(projectIdx) && StringUtils.isNumeric(projectIdx)){
					param.clear();
					param.put("projectIdx", projectIdx);
					
						resultList = new ArrayList<Object>();
						param.put("loginId", loginId);
						resultList = dataDao.selectAllProjectList(param);
						
						if(resultList != null && resultList.size() > 0){
							//update token time
							param.put("uid", String.valueOf(result.get("uid")));
							resultIntegerValue = userDao.updateTokenTime(param);
							
							param.clear();
							param.put("loginId", loginId);
							param.put("projectIdx", projectIdx);
							resultIntegerValue = dataDao.deleteProject(param);
							
							if(resultIntegerValue > 0) {
								resultJSON.put("Code", 100);
								resultJSON.put("Message", Message.code100);
							}else{
								resultJSON.put("Code", 300);
								resultJSON.put("Message", Message.code300);
							}
						}else{
							resultJSON.put("Code", 700);
							resultJSON.put("Message", Message.code700);
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
	
	////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	
	@RequestMapping(value = "/cms/getContentLog/{token}/{loginId}/{idx}", method = RequestMethod.GET, produces="application/json;charset=UTF-8")
	@ResponseBody
	public String getContentLogService(@RequestParam("callback") String callback
			, @PathVariable("token") String token
			, @PathVariable("loginId") String loginId
			, @PathVariable("idx") String idx
			, Model model, HttpServletRequest request) {
		JSONObject resultJSON = new JSONObject();
		
		//token
		param = new HashMap<String, String>();
		param.put("token", token);
		
		try {
			result = userDao.selectUid(param);
			
			if(result != null){
				boolean chkTokenToid = tokenToLoginId(token, loginId);
				if(chkTokenToid){
					if(idx != null && !"".equals(idx) && StringUtils.isNumeric(idx)){
						param.put("loginId", loginId);
						param.put("idx", idx);
						resultList = dataDao.selectContentLogList(param);
						
						if(resultList.size() > 0) {
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
					resultJSON.put("Code", 205);
					resultJSON.put("Message", Message.code205);
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
	
	@RequestMapping(value = "/cms/getContentChild/{token}/{loginId}/{parentIdx}", method = RequestMethod.GET, produces="application/json;charset=UTF-8")
	@ResponseBody
	public String getVideoService(@RequestParam("callback") String callback
			, @PathVariable("token") String token
			, @PathVariable("loginId") String loginId
			, @PathVariable("parentIdx") String parentIdx
			, Model model, HttpServletRequest request) {
		JSONObject resultJSON = new JSONObject();
		
		param = new HashMap<String, String>();
		result = new HashMap<String, String>();
		
		loginId = loginId.replace("&nbsp", "");
		
		try {
			if(loginId != null && !"".equals(loginId)){
				//token
				param.clear();
				param.put("token", token);
				result = userDao.selectUid(param);
				
				if(result == null){
					resultJSON.put("Code", 203);
					resultJSON.put("Message", Message.code203);
					return callback + "(" + resultJSON.toString() + ")";
				}else{
					boolean chkTokenToid = tokenToLoginId(token, loginId);
					if(!chkTokenToid){
						resultJSON.put("Code", 205);
						resultJSON.put("Message", Message.code205);
						return callback + "(" + resultJSON.toString() + ")";
					}
				}
			}
			
			if(!(parentIdx != null && !"".equals(parentIdx) && StringUtils.isNumeric(parentIdx))){
				resultJSON.put("Code", 600);
				resultJSON.put("Message", Message.code600);
				return callback + "(" + resultJSON.toString() + ")";
			}
			
			param.put("parentIdx", parentIdx);
			
			resultList = dataDao.selectContentChildList(param);
			
			if(resultList != null && resultList.size() != 0) {
				resultJSON.put("Code", 100);
				resultJSON.put("Message", Message.code100);
				resultJSON.put("Data", JSONArray.fromObject(resultList));
				
				Map<String, Object> tmpMap = (Map<String, Object>)resultList.get(0);
				if(tmpMap.get("filename") != null){
					String tmpFileName = tmpMap.get("filename").toString();
					if(tmpFileName != null && !"".equals(tmpFileName) && !"null".equals(tmpFileName)){
						tmpFileName = tmpFileName.substring(0,tmpFileName.lastIndexOf("."))+"_modify.gpx";
						resultJSON.put("GpsData", JSONArray.fromObject(getGeoXmltoJson(tmpFileName)));
					}
				}
			}else {
				resultJSON.put("Code", 200);
				resultJSON.put("Message", Message.code200);
			}
		} catch (Exception e) {
			e.printStackTrace();
			resultJSON.put("Code", 800);
			resultJSON.put("Message", Message.code800);
		}
		
		return callback + "(" + resultJSON.toString() + ")";
	}
	
	@RequestMapping(value = "/cms/updateContentTab/{token}/{loginId}/{tabIdx}/{contentIdx}/{type}", method = RequestMethod.POST, produces="application/json;charset=UTF-8")
	@ResponseBody
	public String updateContentTabService(@RequestParam("callback") String callback
			, @PathVariable("token") String token
			, @PathVariable("loginId") String loginId
			, @PathVariable("tabIdx") String tabIdx
			, @PathVariable("contentIdx") String contentIdx
			, @PathVariable("type") String type
			, Model model, HttpServletRequest request) {
		JSONObject resultJSON = new JSONObject();
		
		param = new HashMap<String, String>();
		result = new HashMap<String, String>();
		resultIntegerValue = 0;
		
		loginId = loginId.replace("&nbsp", "");
		
		try {
			if(loginId != null && !"".equals(loginId)){
				//token
				param.clear();
				param.put("token", token);
				result = userDao.selectUid(param);
				
				if(result == null){
					resultJSON.put("Code", 203);
					resultJSON.put("Message", Message.code203);
					return callback + "(" + resultJSON.toString() + ")";
				}else{
					boolean chkTokenToid = tokenToLoginId(token, loginId);
					if(!chkTokenToid){
						resultJSON.put("Code", 205);
						resultJSON.put("Message", Message.code205);
						return callback + "(" + resultJSON.toString() + ")";
					}
				}
			}
			
			if(!(type != null && !"".equals(type) && ("GeoCMS".equals(type) || "GeoProject".equals(type)) && 
					tabIdx != null && !"".equals(tabIdx) && StringUtils.isNumeric(tabIdx) && 
						contentIdx != null && !"".equals(contentIdx) && StringUtils.isNumeric(contentIdx))){
				resultJSON.put("Code", 600);
				resultJSON.put("Message", Message.code600);
				return callback + "(" + resultJSON.toString() + ")";
			}
			
			if("GeoCMS".equals(type)){
				param.put("loginId", loginId);
				param.put("idx", contentIdx);
				resultList = dataDao.selectBoardList(param);
				if(resultList != null && resultList.size() == 1){
					param.put("tabIdx", tabIdx);
					resultIntegerValue = dataDao.updateBoard(param);
				}else{
					resultJSON.put("Code", 700);
					resultJSON.put("Message", Message.code600);
					return callback + "(" + resultJSON.toString() + ")";
				}
			}else if("GeoProject".equals(type)){
				param.put("loginId", loginId);
				param.put("projectIdx", contentIdx);
				resultList = dataDao.selectProjectList(param);
				if(resultList != null && resultList.size() == 1){
					param.put("tabIdx", tabIdx);
					param.put("idx", contentIdx);
					resultIntegerValue = dataDao.updateProject(param);
				}else{
					resultJSON.put("Code", 700);
					resultJSON.put("Message", Message.code600);
					return callback + "(" + resultJSON.toString() + ")";
				}
			}
			
			if(resultIntegerValue > 0) {
				resultJSON.put("Code", 100);
				resultJSON.put("Message", Message.code100);
			}else {
				resultJSON.put("Code", 200);
				resultJSON.put("Message", Message.code200);
			}
		} catch (Exception e) {
			e.printStackTrace();
			resultJSON.put("Code", 800);
			resultJSON.put("Message", Message.code800);
		}
		
		return callback + "(" + resultJSON.toString() + ")";
	}
	
	@RequestMapping(value = "/cms/saveWorldFile/{token}/{loginId}/{projectIdx}", method = RequestMethod.POST, produces="application/json;charset=UTF-8")
	@ResponseBody
	public String saveWorldFileService(@RequestParam("callback") String callback
		, @PathVariable("token") String token
		, @PathVariable("loginId") String loginId
		, @PathVariable("projectIdx") String projectIdx
		, Model model, HttpServletRequest request) {
		JSONObject resultJSON = new JSONObject();
		param = new HashMap<String, String>();
		param2 = new HashMap<String, String>();
		result = new HashMap<String, String>();
		List<Object> resList = new ArrayList<Object>();
		
		//token
		param.clear();
		param.put("token", token);
		
		try {
			result = userDao.selectUid(param);
			
			if(result != null){
				boolean chkTokenToid = tokenToLoginId(token, loginId);
				if(!chkTokenToid){
					resultJSON.put("Code", 205);
					resultJSON.put("Message", Message.code205);
					return callback + "(" + resultJSON.toString() + ")";
				}
				
				if(!(projectIdx != null && !"".equals(projectIdx) && StringUtils.isNumeric(projectIdx))){
					resultJSON.put("Code", 600);
					resultJSON.put("Message", Message.code600);
					return callback + "(" + resultJSON.toString() + ")";
				}
				
				param.clear();
				param.put("loginId", loginId);
				param.put("projectIdx", projectIdx);
				resultList = dataDao.selectProjectList(param);
				
				if(!(resultList != null && resultList.size() > 0)){
					resultJSON.put("Code", 700);
					resultJSON.put("Message", Message.code300);
					return callback + "(" + resultJSON.toString() + ")";
				}
				
				//update token time
				param.put("uid", String.valueOf(result.get("uid")));
				resultIntegerValue = userDao.updateTokenTime(param);
				
				//*************************************************************************************************************************
				String uploadType = "GeoPhoto";
				
				//파일 정보 저장 변수
				ArrayList<Map<String,String>> fileListP = new ArrayList<Map<String,String>>();
				List<Map<String,String>> fileListV = new ArrayList<Map<String,String>>();
				String saveUserPath = request.getSession().getServletContext().getRealPath("/")+ "upload";
				File saveUserPathDir = new File(saveUserPath);
			    if(!saveUserPathDir.exists()) saveUserPathDir.mkdir();
				ArrayList<FileItem> fileItemListV = new ArrayList<FileItem>();
				Map<String,String> fileMap = new HashMap<String, String>();
				int uploadMaxSize = 2*1024*1024*1024; //1024MB = 1GB
			    File tempDir = new File(saveUserPath+"/"+"tmp");
				File uploadDir = new File(saveUserPath);
				List items = null;
				Iterator iter = null;
				List<String> saveFileList = new ArrayList<String>();
			
				//파일 업로드
				boolean isMultipart = ServletFileUpload.isMultipartContent(request); // 멀티파트인지 체크
				System.out.println("isMultipart : "+isMultipart);
				
				FTPClient ftp = null; // FTP Client 객체 
				int reply = 0;
				
				DiskFileItemFactory factory = new DiskFileItemFactory(uploadMaxSize, tempDir);
				ServletFileUpload upload = new ServletFileUpload(factory);
				
				FileItem item = null;
				
				String fileName = "";
				String fileIdxArrStr = "";
				String changeFileName = "";
				String uploadFilePath = "";
				String subFix = "";
				
				try {
					if(isMultipart) {
						ftp = new FTPClient(); // FTP Client 객체 생성 
						ftp.setControlEncoding("UTF-8"); // 문자 코드를 UTF-8로 인코딩 
						ftp.connect(serverUrlStr, Integer.parseInt(portNumStr)); // 서버접속 " "안에 서버 주소 입력 또는 "서버주소", 포트번호 
						
						reply = ftp.getReplyCode();//a
						if(!FTPReply.isPositiveCompletion(reply)) {
							ftp.disconnect();
							resultJSON.put("Code", 400);
							resultJSON.put("Message", Message.code400);
							return callback + "(" + resultJSON.toString() + ")";
					    }
						
						if(!ftp.login(userIdStr, userPassStr)) {
							ftp.logout();
							resultJSON.put("Code", 400);
							resultJSON.put("Message", Message.code400);
							return callback + "(" + resultJSON.toString() + ")";
					    }
						
						ftp.setFileType(FTP.BINARY_FILE_TYPE);
					    ftp.enterLocalPassiveMode();
			
					    ftp.changeWorkingDirectory(saveFilePathStr +"/" +uploadType); // 작업 디렉토리 변경
					    reply = ftp.getReplyCode();
					    if (reply == 550) {
					    	ftp.makeDirectory(saveFilePathStr +"/" +uploadType);
					    	ftp.changeWorkingDirectory(saveFilePathStr +"/" +uploadType ); // 작업 디렉토리 변경
					    }
						//--------------------------------------------------------------------------------------------
						
						upload.setSizeMax(uploadMaxSize);
						items = upload.parseRequest(request);
						iter = items.iterator();
						
					    
						while(iter.hasNext()) {
							uploadFilePath = "";
							changeFileName = "";
							fileIdxArrStr = "";
							subFix = "";
							fileMap = new HashMap<String, String>();
							
							item = (FileItem)iter.next();
							if(!item.isFormField()) {
								fileName = item.getName();
								System.out.println("FileName : "+fileName);
								
								if(fileName != null && fileName != ""){
									subFix = fileName.substring(fileName.lastIndexOf("."),fileName.length());
									fileName = fileName.substring(0, fileName.lastIndexOf("."));
									
									if(subFix != null & subFix != ""){
										param2 = new HashMap<String, String>();
										param2.put("projectIdx", projectIdx);
										param2.put("searchWord", "Y");
										
										if(".gpx".equals(subFix)){
											param2.put("thumbNail", fileName);
											resList = dataDao.selectVideoFileList(param2);
											if(resList != null && resList.size() > 0){
												fileItemListV.add(item);
											}
										}else{
											param2.put("fileName", fileName);
											resList = dataDao.selectImageFileList(param2);
										}
										
										if(resList != null && resList.size()>0){
											for(int j=0; j<resList.size();j++){
												HashMap<String,String> tmpHmap = (HashMap<String,String>)resList.get(j);
												if(tmpHmap != null && tmpHmap.get("idx") != null){
													if(".gpx".equals(subFix) && tmpHmap.get("thumbnail") != null){
														changeFileName = tmpHmap.get("thumbnail").toString();
														if(changeFileName != null && !"".equals(changeFileName)){
															changeFileName = changeFileName.substring(0, changeFileName.lastIndexOf("_thumb"));
															changeFileName += "_ogg"  + subFix;
														}
													}else if(tmpHmap.get("filename") != null){
														changeFileName = tmpHmap.get("filename").toString();
														if(changeFileName != null && !"".equals(changeFileName)){
															changeFileName = changeFileName.substring(0, changeFileName.lastIndexOf(".")) + subFix;
														}
													}else{
														resultJSON.put("Code", 400);
														resultJSON.put("Message", Message.code400);
														return callback + "(" + resultJSON.toString() + ")";
													}
													
													if(".gpx".equals(subFix)){
														uploadFilePath = uploadDir + File.separator + "GeoVideo" + File.separator +  changeFileName;
													}else{
														uploadFilePath = uploadDir + "/GeoPhoto/"+ changeFileName;
													}
													
													System.out.println("uploadFile : "+uploadFilePath);
													
													fileIdxArrStr += String.valueOf(tmpHmap.get("idx"));
													if(j<resList.size()-1){
														fileIdxArrStr += ",";
													}
												}
											}
											fileMap.put("file", uploadFilePath);
											fileMap.put("idx", fileIdxArrStr);
											
											if(".gpx".equals(subFix)){
												fileListV.add(fileMap);
											}else{
												item.write(new File(uploadFilePath));
												saveFileList.add(uploadFilePath);
												fileListP.add(fileMap);
											}
											resultIntegerValue = 1;
										}
									}
								}
							}
						}//end while
					}
				} catch (Exception e) {
					e.printStackTrace();
					resultJSON.put("Code", 400);
					resultJSON.put("Message", Message.code400);
					return callback + "(" + resultJSON.toString() + ")";
				}
				
				if(fileListP != null && fileListP.size() > 0){
					imageSaveStart("", "", fileListP, saveFileList, "worldFile");
				}
				if(fileListV != null && fileListV.size() > 0){
					videoSaveStart("", "", "", "", fileListV, null, fileItemListV, saveUserPath, "worldFile");
				}
				/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
				
				if(resultIntegerValue > 0) {
					resultJSON.put("Code", 100);
					resultJSON.put("Message", Message.code100);
				}else{
					resultJSON.put("Code", 300);
					resultJSON.put("Message", Message.code300);
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
	
	@RequestMapping(value = "/cms/copyProject/{token}/{loginId}/{projectName}/{parentIdx}/{copySeq_arr}", method = RequestMethod.GET, produces="application/json;charset=UTF-8")
	@ResponseBody
	public String saveProjectService(@RequestParam("callback") String callback
			, @PathVariable("token") String token
			, @PathVariable("loginId") String loginId
			, @PathVariable("projectName") String projectName
			, @PathVariable("parentIdx") String parentIdx
			, @PathVariable("copySeq_arr") String copySeq_arr
			, Model model, HttpServletRequest request, HttpServletResponse response) {
		JSONObject resultJSON = new JSONObject();
		param = new HashMap<String, String>();
		result = new HashMap<String, String>();
		String saveIdx = "";
		String shareType = "";
		List<Map<String, Object>> copySeqArr = null;
		
		//token
		param.clear();
		param.put("token", token);
		
		try {
			result = userDao.selectUid(param);
			
			if(result != null){
				boolean chkTokenToid = tokenToLoginId(token, loginId);
				if(!chkTokenToid){
					resultJSON.put("Code", 205);
					resultJSON.put("Message", Message.code205);
					return callback + "(" + resultJSON.toString() + ")";
				}
				
				if(!(projectName != null && projectName != "" && projectName != "null" && parentIdx != null && parentIdx != "" && StringUtils.isNumeric(parentIdx) &&
						copySeq_arr != null && copySeq_arr != "")){
					resultJSON.put("Code", 600);
					resultJSON.put("Message", Message.code600);
					return callback + "(" + resultJSON.toString() + ")";
				}
				
				ObjectMapper mapper = new ObjectMapper();
				try {
					copySeqArr = mapper.readValue(copySeq_arr, new TypeReference<List<Map<String, Object>>>(){});
				} catch (Exception e) {
					e.printStackTrace();
					resultJSON.put("Code", 600);
					resultJSON.put("Message", Message.code600);
					return callback + "(" + resultJSON.toString() + ")";
				}
				
				if(!(copySeqArr != null && copySeqArr.size() > 0)){
					resultJSON.put("Code", 600);
					resultJSON.put("Message", Message.code600);
					return callback + "(" + resultJSON.toString() + ")";
				}
				
				param.put("loginId", loginId);
				param.put("projectIdx", parentIdx);
				resultList = dataDao.selectProjectList(param);
				if(resultList != null && resultList.size() == 1){
					Map<String, String> tmpResMap = (Map<String, String>)resultList.get(0);
					if(tmpResMap != null){
						shareType = String.valueOf(tmpResMap.get("sharetype")) ;
						//update token time
						param.put("uid", String.valueOf(result.get("uid")));
						resultIntegerValue = userDao.updateTokenTime(param);
						
						projectName = dataReplaceFun(projectName);
						
						param.clear();
						param.put("loginId", loginId);
						param.put("projectName", projectName);
						param.put("shareType", shareType);
						param.put("tabIdx", String.valueOf(tmpResMap.get("tabidx")));
						resultIntegerValue = dataDao.insertProject(param);
						if(resultIntegerValue == 1){
							if(param != null && param.get("idx") != null){
								saveIdx = String.valueOf(param.get("idx"));
								
								if(shareType != null && "2".equals(shareType)){
									param = new HashMap<String, String>();
									param.put("projectIdx", parentIdx);
									param.put("shareIdx", saveIdx);
									param.put("shareKind", "GeoProject");
									resultIntegerValue = userDao.insertShareFormProject(param);
								}
								//-------------------------------------------------------------------------
								HashMap<String, Object> copyParam = new HashMap<String, Object>();
								HashMap<String, Object> objParam = new HashMap<String, Object>();
								HashMap<String, String> strParam = new HashMap<String, String>();
								List<Object> copyList = new ArrayList<Object>();
								String childShareType = "";
								String childIdx = "";
								String childDataKind = "";
								String childIdx2 = "";
								
								copyParam.put("copySeqArr", copySeqArr);
								copyParam.put("copyOrder", "Y");
								copyList = dataDao.selectAllContentList(copyParam);
								if(copyList != null && copyList.size() > 0 && copyList.size() == copySeqArr.size()){
									for(int m = 0; m<copyList.size(); m++){
										//data save
										objParam = (HashMap<String, Object>)copyList.get(m);
										
										if(objParam != null && objParam.get("idx") != null && objParam.get("datakind") != null){
											childIdx = String.valueOf(objParam.get("idx"));
											childShareType = String.valueOf(objParam.get("sharetype"));
											childDataKind = String.valueOf(objParam.get("datakind"));
											
											if("GeoPhoto".equals(childDataKind)){
												objParam.put("projectidx", saveIdx);
												objParam.put("seqnum", (m+1));
												objParam.put("loginid", loginId);
												resultIntegerValue = dataDao.insertImage(objParam);
												
												if(objParam != null && objParam.get("sharetype") != null && objParam.get("idx") != null){
													if(childShareType != null && "2".equals(childShareType)){
														param = new HashMap<String, String>();
														param.put("projectIdx", saveIdx);
														param.put("shareIdx", String.valueOf(objParam.get("idx")));
														param.put("shareKind", "GeoPhoto");
														resultIntegerValue = userDao.insertShareFormProject(param);
													}
												}
											}else{
												strParam = (HashMap<String, String>)copyList.get(m);
												strParam.put("projectidx", saveIdx);
												strParam.put("seqnum", String.valueOf((m+1)));
												strParam.put("loginid", loginId);
												
												resultIntegerValue = dataDao.insertVideo(strParam);
												if(resultIntegerValue == 1){
													childIdx2 = String.valueOf(strParam.get("idx"));
													objParam = new HashMap<String, Object>();
													objParam.put("newParentIdx", childIdx2);
													objParam.put("oldParentIdx", childIdx);
													resultIntegerValue = dataDao.insertChildContentFromParent(objParam);
													
													if(strParam != null && strParam.get("sharetype") != null && strParam.get("idx") != null){
														if(childShareType != null && "2".equals(childShareType)){
															param = new HashMap<String, String>();
															param.put("projectIdx", childIdx);
															param.put("shareIdx", String.valueOf(strParam.get("idx")));
															param.put("shareKind", "GeoVideo");
															resultIntegerValue = userDao.insertShareFormProject(param);
														}
													}
												}
											}
										}
									}
								}
								
								//-------------------------------------------------------------------------
							}
						}
					}
				}else{
					resultJSON.put("Code", 700);
					resultJSON.put("Message", Message.code600);
					return callback + "(" + resultJSON.toString() + ")";
				}
				
				if(resultIntegerValue > 0) {
					resultJSON.put("Code", 100);
					resultJSON.put("Message", Message.code100);
					resultJSON.put("Data", saveIdx);
				}else{
					resultJSON.put("Code", 300);
					resultJSON.put("Message", Message.code300);
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
	
	///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	
	//token , loginId 
	public boolean tokenToLoginId(String token, String loginId){
		boolean chk = false;
		result = new HashMap<String, String>();
		
		param = new HashMap<String, String>();
		param.put("token", token);
		param.put("id", loginId);
		param.put("searchTokenToUser", "Y");
		param.put("searchToken", "Y");
		
		result = userDao.selectUid(param);
		if(result != null){
			chk = true;
		}
		return chk;
	}
	
	//content Type 
	public boolean checkUpdateBase(String contentTab, String contentTabType, String contentNum, String contentTabIdx,
			String boardTab,  String boardNum, String boardTabIdx, String openAPI, String latestView, String mapZoom){
		boolean chk = true;
		
		if(contentTab != null && !"".equals(contentTab) && !"null".equals(contentTab) &&
			contentTabType != null && !"".equals(contentTabType) && !"null".equals(contentTabType) &&
			contentNum != null && !"".equals(contentNum) && !"null".equals(contentNum) &&
			contentTabIdx != null && !"".equals(contentTabIdx) && !"null".equals(contentTabIdx)){
			
			if(!(contentTab != null && "&nbsp".equals(contentTab) && contentTabType != null && "&nbsp".equals(contentTabType) && 
					contentNum != null && "&nbsp".equals(contentNum) && contentTabIdx != null && "&nbsp".equals(contentTabIdx))){
				if(!checkContentTypeC(contentTab, contentTabType, contentNum , contentTabIdx) || !checkListIsNumber(contentNum)){
					chk = false;
				}
			}
		}else{
			chk = false;
		}
		
		if(boardTab != null && !"".equals(boardTab) && !"null".equals(boardTab) &&
			boardNum != null && !"".equals(boardNum) && !"null".equals(boardNum) &&
			boardTabIdx != null && !"".equals(boardTabIdx) && !"null".equals(boardTabIdx)){
			
			if(!(boardTab != null && "&nbsp".equals(boardTab) && boardNum != null && "&nbsp".equals(boardNum) && 
					boardTabIdx != null && "&nbsp".equals(boardTabIdx))){
				if(!checkContentTypeB(boardTab, boardNum, boardTabIdx) ||  !checkListIsNumber(boardNum)){
					chk = false;
				}
			}
		}else{
			chk = false;
		}
		
		if(openAPI != null && !"".equals(openAPI) && !"null".equals(openAPI) &&
			latestView != null && !"".equals(latestView) && !"null".equals(latestView) &&
			mapZoom != null && !"".equals(mapZoom) && !"null".equals(mapZoom)){
			
			if(!("0".equals(openAPI) || "1".equals(openAPI)) || !("0".equals(latestView) || "1".equals(latestView)) || !StringUtils.isNumeric(mapZoom)){
				chk = false;
			}
		}else{
			chk = false;
		}

		return chk;
	}
		
	//content Type 
	public boolean checkContentTypeC(String contentTabStr, String contentTypeStr, String contentNumStr, String contentTabIdxStr){
		boolean chk = true;
		
		if(contentTabStr != null && !"".equals(contentTabStr) && !"null".equals(contentTabStr) &&
				contentTypeStr != null && !"".equals(contentTypeStr) && !"null".equals(contentTypeStr) &&
				contentNumStr != null && !"".equals(contentNumStr) && !"null".equals(contentNumStr) &&
				contentTabIdxStr != null && !"".equals(contentTabIdxStr) && !"null".equals(contentTabIdxStr)){
			String[] tmpTab = contentTabStr.split(",");
			String[] tmpContentType = contentTypeStr.split(",");
			String[] tmpNum = contentNumStr.split(",");
			String[] tmpdx = contentTabIdxStr.split(",");
			
			if(tmpTab.length <= 0 || tmpContentType.length <= 0 || tmpNum.length <= 0 || tmpdx.length <= 0 || 
					tmpTab.length != tmpContentType.length || tmpTab.length != tmpNum.length || tmpTab.length != tmpdx.length){
				chk = false;
			}
			
			for(int i=0;i<tmpContentType.length;i++){
				if(!"list".equals(tmpContentType[i]) && !"gellery".equals(tmpContentType[i])){
					chk = false;
				}
			}
			
		}else{
			chk = false;
		}
		
		return chk;
	}
	
	public boolean checkContentTypeB(String boardTabStr, String boardNumStr, String boardTabIdxStr){
		boolean chk = true;
		
		if(boardTabStr != null && !"".equals(boardTabStr) && !"null".equals(boardTabStr) &&
				boardNumStr != null && !"".equals(boardNumStr) && !"null".equals(boardNumStr) &&
				boardTabIdxStr != null && !"".equals(boardTabIdxStr) && !"null".equals(boardTabIdxStr)){
			String[] tmpBoardTab = boardTabStr.split(",");
			String[] tmpBoardNum = boardNumStr.split(",");
			String[] tmpBoardIdx = boardTabIdxStr.split(",");
			
			if(tmpBoardTab.length <= 0 || tmpBoardNum.length <= 0 || tmpBoardIdx.length <= 0 ||
					tmpBoardTab.length != tmpBoardNum.length || tmpBoardTab.length != tmpBoardIdx.length){
				chk = false;
			}
		}else{
			chk = false;
		}
		
		return chk;
	}
	
	//string arr is number check
	public boolean checkListIsNumber(String numberStr){
		boolean chk = true;
		
		if(numberStr != null && !"".equals(numberStr)){
			String[] numArr = numberStr.split(",");
			for(String tmpNum : numArr){
				if(!StringUtils.isNumeric(tmpNum)){
					chk = false;
				}
			}
		}else{
			chk = false;
		}
		
		return chk;
	}
	
	//content list Type 
	public boolean checkContentListType(String contentListTypeStr, String type){
		boolean chk = false;
		String[] contentTypeList = {"list","one", "latest", "marker"};
		String[] viewTypeList = {"GeoCMS","GeoPhoto", "GeoVideo", "marker"};
		String[] projectTypeList = {"list", "marker"};
		String[] shareTypeList = {"0", "1", "2"};
		String[] userTypeList = {"ADMIN", "DELETE", "MODIFY", "WRITE"};
		String[] searchTypeList = {"ID", "EMAIL", "REG_DATE", "TYPE"};
		String[] searchShareList = {"list", "search", "first"};
		String[] shareKindList = {"GeoCMS","GeoPhoto", "GeoVideo", "GeoProject"};
		String[] dataKindList = {"GeoCMS","GeoPhoto", "GeoVideo"};
 		
		if("viewType".equals(type)){
			contentTypeList = viewTypeList;
		}else if("projectType".equals(type)){
			contentTypeList = projectTypeList;
		}else if("shareType".equals(type)){
			contentTypeList = shareTypeList;
		}else if("userType".equals(type)){
			contentTypeList = userTypeList;
		}else if("searchType".equals(type)){
			contentTypeList = searchTypeList;
		}else if("searchShare".equals(type)){
			contentTypeList = searchShareList;
		}else if("shareKind".equals(type)){
			contentTypeList = shareKindList;
		}else if("dataKind".equals(type)){
			contentTypeList = dataKindList;
		}
		
		if(contentListTypeStr != null && !"".equals(contentListTypeStr) && !"null".equals(contentListTypeStr)){
			for(int i=0;i<contentTypeList.length;i++){
				if(contentListTypeStr.equals(contentTypeList[i])){
					chk = true;
					if("board".equals(type) && "marker".equals(contentTypeList[i])){
						chk = false;
					}
					if("contentB".equals(type) && "one".equals(contentTypeList[i])){
						chk = false;
					}
				}
			}
		}
		return chk;
	}
	
	public boolean checkDate(String text){
        try {
        	SimpleDateFormat sdf = new SimpleDateFormat("yyyyMMdd");
        	Date data1 = sdf.parse(text);
            return true;
        } catch (Exception e) {
            return false;
        }
    }
	
	public void imageSaveStart(String loginId, String logKey, List<Map<String,String>> fileList, List<String> saveFiles, String fileType){
		SaveController saveController = new SaveController(loginId, logKey, fileList, saveFiles, serverUrlStr, userIdStr, userPassStr, portNumStr, saveFilePathStr, fileType);
		saveController.setDataAPI(dataDao);
		saveController.start();
	}
	
	public void videoSaveStart(String loginId, String logKey, String saveFileNameOrg, String parentIndex,
			List<Map<String,String>> files, List<String> filesXml, ArrayList<FileItem> fileItemList, String saveUserPath, String fileType){
		VideoSaveController videoSaveController = new VideoSaveController(loginId, logKey, saveFileNameOrg, parentIndex, files, filesXml, fileItemList, saveUserPath, serverUrlStr, userIdStr, userPassStr, portNumStr, saveFilePathStr, fileType);
		videoSaveController.setDataAPI(dataDao);
		videoSaveController.start();
	}
	
	public List<Map<String,Object>> getGeoXmltoJson(String file_name) throws IOException {
		
		System.out.println(file_name);
		
		String result = "";
		List<Map<String,Object>> resList = new ArrayList<Map<String,Object>>();
		Map<String,Object> resMap = new HashMap<String, Object>();
		
		file_name = "http://"+ serverUrlStr + "/shares/"+saveFilePathStr +"/GeoVideo/"+file_name;
		
		try {			   
			URL gamelan = new URL(file_name);
			Authenticator.setDefault(new Authenticator()
			{
			  @Override
			  protected PasswordAuthentication getPasswordAuthentication()
			  {
			    return new PasswordAuthentication(userIdStr, userPassStr.toCharArray());
			  }
			});
			HttpURLConnection urlConnection = (HttpURLConnection)gamelan.openConnection();
            urlConnection.connect();
          
            if(urlConnection.getResponseCode() == HttpURLConnection.HTTP_OK){
            	BufferedReader in = new BufferedReader(new InputStreamReader(urlConnection.getInputStream(), "UTF-8"));

                String inputLine;
                while ((inputLine = in.readLine()) != null){
                	System.out.println(inputLine);
                	result += inputLine;
                }
                in.close();
            }
            
            if(result != null && !"".equals(result)){
            	org.json.JSONObject xmlJSONObj = XML.toJSONObject(result);//"gpx":{"trk":{"trkseg":{"trkpt":[
                org.json.JSONObject gpxData = (org.json.JSONObject)xmlJSONObj.get("gpx");
                org.json.JSONObject trkData = (org.json.JSONObject)gpxData.get("trk");
                org.json.JSONObject trksegData = (org.json.JSONObject)trkData.get("trkseg");
                org.json.JSONArray jsonArr = (org.json.JSONArray)trksegData.get("trkpt");
                if(jsonArr != null && jsonArr.length() > 0){
                	for(int i=0; i<jsonArr.length();i++){
                		resMap = new HashMap<String, Object>();
                		xmlJSONObj = (org.json.JSONObject)jsonArr.get(i);
                		resMap.put("lon", xmlJSONObj.get("lon"));
                		resMap.put("lat", xmlJSONObj.get("lat"));
                		resList.add(resMap);
                	}
                }
            }
            
		} catch (Exception e) {
			e.printStackTrace();
		}
		
		return resList;
	}
	
	public String dataReplaceFun(String oneData) {
		String replaceResultData = "";
		
		if(oneData != null){
			replaceResultData = oneData.replaceAll("&sbsp","/");
			replaceResultData = replaceResultData.replaceAll("&nbsp", "");
			replaceResultData = replaceResultData.replaceAll("&mbsp","?");
			replaceResultData = replaceResultData.replaceAll("&pbsp","#");
			replaceResultData = replaceResultData.replaceAll("&obsp",".");
			replaceResultData = replaceResultData.replaceAll("&lt","<");
			replaceResultData = replaceResultData.replaceAll("&gt",">");
			replaceResultData = replaceResultData.replaceAll("&bt","\\\\");
			replaceResultData = replaceResultData.replaceAll("&mt","%");
			replaceResultData = replaceResultData.replaceAll("&vbsp",";");
			replaceResultData = replaceResultData.replaceAll("&rnsp","\r");
			replaceResultData = replaceResultData.replaceAll("&nnsp","\n");
			replaceResultData = replaceResultData.replaceAll("&xbsp",",");
		}
		
		return replaceResultData;
	}
}
