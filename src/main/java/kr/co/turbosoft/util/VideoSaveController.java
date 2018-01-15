package kr.co.turbosoft.util;

import java.io.File;
import java.io.FileInputStream;
import java.math.BigDecimal;
import java.net.Authenticator;
import java.net.HttpURLConnection;
import java.net.PasswordAuthentication;
import java.net.URL;
import java.text.SimpleDateFormat;
import java.util.ArrayList;
import java.util.Date;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import javax.xml.parsers.DocumentBuilder;
import javax.xml.parsers.DocumentBuilderFactory;
import javax.xml.transform.Result;
import javax.xml.transform.Transformer;
import javax.xml.transform.TransformerFactory;
import javax.xml.transform.dom.DOMSource;
import javax.xml.transform.stream.StreamResult;

import org.apache.commons.fileupload.FileItem;
import org.apache.commons.io.FileUtils;
import org.apache.commons.net.ftp.FTP;
import org.apache.commons.net.ftp.FTPClient;
import org.apache.commons.net.ftp.FTPReply;
import org.w3c.dom.Document;
import org.w3c.dom.Element;
import org.w3c.dom.Node;
import org.w3c.dom.NodeList;

import kr.co.turbosoft.dao.DataDao;

public class VideoSaveController extends Thread{
	private DataDao dataDao = null;
	
	private String loginId;
	private String logKey;
	private String saveFileNameOrg;
	private String parentIndex;
	private List<Map<String,String>> files;
	private List<String> filesXml;
	private ArrayList<FileItem> fileItemList;
	
	private String saveUserPath;
	private String serverUrlStr;
	private String userIdStr;
	private String userPassStr;
	private String portNumStr;
	private String saveFilePathStr;
	private String fileType;
	
	public void setDataAPI(DataDao dataDao){
		this.dataDao = dataDao;
	}
	
	public VideoSaveController(String loginId, String logKey, String saveFileNameOrg, String parentIndex, List<Map<String,String>> files, List<String> filesXml, ArrayList<FileItem> fileItemList,
			String saveUserPath, String serverUrlStr, String userIdStr, String userPassStr, String portNumStr, String saveFilePathStr, String fileType) {
        this.loginId = loginId;
        this.logKey = logKey;
        this.saveFileNameOrg = saveFileNameOrg;
        this.parentIndex = parentIndex;
        this.files = files;
        this.filesXml = filesXml;
        this.fileItemList = fileItemList;
        
        this.saveUserPath = saveUserPath;
        this.serverUrlStr = serverUrlStr;
        this.userIdStr = userIdStr;
        this.userPassStr = userPassStr;
        this.portNumStr = portNumStr;
        this.saveFilePathStr = saveFilePathStr;
        this.fileType = fileType;
    }

	@Override
	public void run() {
        System.out.println("thread run.");
		
        FTPClient ftp = null; // FTP Client 객체 
		FileInputStream fis = null; // File Input Stream 
		int reply = 0;
//		File removeFile = null;
		List<File> removeFileList = new ArrayList<File>();
		
		List<Object> resIdx = new ArrayList<Object>();
		HashMap<String, Object> objParam = new HashMap<String, Object>();
		HashMap<String, String> param2 = new HashMap<String, String>();
		HashMap<String, String> param3 = new HashMap<String, String>();
		List<Map<String, Object>> fileNameList = new ArrayList<Map<String, Object>>();
		HashMap<String, Object> fileNameMap = new HashMap<String, Object>();
		
		param3.clear();
		param3.put("loginId", loginId);
		param3.put("idx", String.valueOf(logKey));
		
		try{
			ftp = new FTPClient(); // FTP Client 객체 생성 
			ftp.setControlEncoding("UTF-8"); // 문자 코드를 UTF-8로 인코딩 
			ftp.connect(serverUrlStr, Integer.parseInt(portNumStr)); // 서버접속 " "안에 서버 주소 입력 또는 "서버주소", 포트번호 
			
			reply = ftp.getReplyCode();//
			if(!FTPReply.isPositiveCompletion(reply)) {
				ftp.disconnect();
				if(fileType != null && "videoFile".equals(fileType)){
					param3.put("status", "ERROR");
					dataDao.updateLog(param3);
				}
				return;
		    }
			
			if(!ftp.login(userIdStr, userPassStr)) {
				ftp.logout();
				if(fileType != null && "videoFile".equals(fileType)){
					param3.put("status", "ERROR");
					dataDao.updateLog(param3);
				}
				return;
		    }
			
			ftp.setFileType(FTP.BINARY_FILE_TYPE);
		    ftp.enterLocalPassiveMode();

		    ftp.changeWorkingDirectory(saveFilePathStr +"/GeoVideo"); // 작업 디렉토리 변경
		    reply = ftp.getReplyCode();
		    if (reply == 550) {
		    	ftp.makeDirectory(saveFilePathStr +"/GeoVideo");
		    	ftp.changeWorkingDirectory(saveFilePathStr +"/GeoVideo"); // 작업 디렉토리 변경
		    }
		}catch(Exception e){
			e.printStackTrace();
			if(fileType != null && "videoFile".equals(fileType)){
				param3.put("status", "ERROR");
				dataDao.updateLog(param3);
			}
			return;
		}
		//--------------------------------------------------------------------------------------------
		HashMap<String, String> param4 = new HashMap<String, String>();
		Map<String, String> fileMap = new HashMap<String, String>();
		List<Object> removeList = new ArrayList<Object>();
		File newXmlFile = null;
		FileItem item = null;
	    int gpxIdx = 0;
	    String tmpGpxFilePathDirFull = "";
	    String tmpGpxFilePathDir = "";
	    String latitude = "";
		String longitude = "";
		String fileName = "";
		String tmpPathStr = "";
		
		//video date time
		List<String> ffmpegFileArr = new ArrayList<String>();
		
		try{
			if(fileType != null && "videoFile".equals(fileType)){
				ffmpegFileArr = new ArrayList<String>();
				for(int j=0; j<fileItemList.size(); j++){
					item = fileItemList.get(j);
					tmpGpxFilePathDirFull = "";
					fileNameMap = new HashMap<String, Object>();
					fileMap = new HashMap<String, String>();
					newXmlFile = null;
					fileName = "";
					tmpGpxFilePathDirFull = "";
					tmpPathStr = "";
					
					if(!item.isFormField()) {
						fileName = item.getName();
						System.out.println("FileName : "+fileName);
						if(fileName != null && !"".equals(fileName)){
							fileMap = files.get(j);
							tmpGpxFilePathDirFull = String.valueOf(fileMap.get("file"));
							System.out.println("tmpGpxFilePathDirFull : " + tmpGpxFilePathDirFull);
//							tmpGpxFilePathDir = tmpGpxFilePathDirFull.substring(0, tmpGpxFilePathDirFull.lastIndexOf("\\"));
							tmpGpxFilePathDir = tmpGpxFilePathDirFull.substring(0, tmpGpxFilePathDirFull.lastIndexOf(File.separator));
							
							if(fileName.indexOf(".gpx") >= 0){
								if(gpxIdx == 0){
									if(fileMap != null){
//										tmpGpxFilePathDir = tmpGpxFilePathDirFull.substring(0, tmpGpxFilePathDirFull.lastIndexOf("\\"));
										tmpGpxFilePathDir = tmpGpxFilePathDirFull.substring(0, tmpGpxFilePathDirFull.lastIndexOf(File.separator));
										newXmlFile = new File(tmpGpxFilePathDir + File.separator + saveFileNameOrg + "_ogg.gpx");
										System.out.println("newXmlFile : " + newXmlFile);
										item.write(newXmlFile);
										gpxIdx = 1;
									}
								}else{
									item.write(new File(tmpGpxFilePathDirFull));
								}
							}else if(fileName.indexOf(".gpx") < 0){
								item.write(new File(tmpGpxFilePathDirFull));
								tmpPathStr = tmpGpxFilePathDirFull.replace("_ogg.ogg", "");
								
								fileNameMap.put("file", tmpPathStr);
								fileNameMap.put("idx", fileMap.get("idx"));
								fileNameList.add(fileNameMap);
								
								if(filesXml != null && filesXml.size() > 0){
									ffmpegFileArr.add(tmpGpxFilePathDirFull);
								}
							}
							//FTP end---------------------------------------------------------------------------------------------------------
							
						}//file name not null
					}
				}
				
				if(filesXml != null && filesXml.size() > 0){
					DocumentBuilderFactory dbf = DocumentBuilderFactory.newInstance();
					dbf.setIgnoringElementContentWhitespace(true);
					DocumentBuilder db = dbf.newDocumentBuilder();
					
					String newXmlFilePathStr = tmpGpxFilePathDir + File.separator + saveFileNameOrg + "_ogg.gpx";
					File fXmlSaveFile = new File(newXmlFilePathStr);
					Document firstDoc = db.parse(fXmlSaveFile);
					
					Node results = firstDoc.getElementsByTagName("trkseg").item(0);
					NodeList nList1 = firstDoc.getElementsByTagName("trkpt");
					
					/////////////////////////////////////////////////////////////
					Node modifyNode = firstDoc.getElementsByTagName("trkseg").item(0);
					
					System.out.println("nList1 : "+ nList1.getLength());
					
					for(int k=0;k<filesXml.size();k++){
						if(k > 0){
							Document merge = db.parse(filesXml.get(k));
						    Node nextResults = merge.getElementsByTagName("trkseg").item(0);
						      while (nextResults.hasChildNodes()) {
						        Node kid = nextResults.getFirstChild();
						        if(kid != null){
						        	////////////////////////////////////////////////
						        	modifyNode.appendChild(kid);
						        	kid = firstDoc.importNode(kid, true);
						        	results.appendChild(kid);
				        			////////////////////////////////////////////////
						        }
						        nextResults.removeChild(kid);
						      }
						      
						    if(k == filesXml.size()-1){
						    	Node gpxNode = firstDoc.getElementsByTagName("gpx").item(0);
						    	Node trkNode = firstDoc.getElementsByTagName("trk").item(0);
						    	
							    firstDoc.importNode(gpxNode, true);
							    firstDoc.importNode(trkNode, true);
							    firstDoc.importNode(results, true);
							    
							    trkNode.appendChild(results);
							    gpxNode.appendChild(trkNode);
						    	
						    	TransformerFactory transformerFactory = TransformerFactory.newInstance();
							    Transformer transformer = transformerFactory.newTransformer();
							    DOMSource source = new DOMSource(gpxNode);
							    Result result = new StreamResult(new File(newXmlFilePathStr));
							    transformer.transform(source, result);
						    }
						}
						
						if(k == 0){
							System.out.println("----------------------------");
							Element eElement = (Element)nList1.item(0);
							latitude = eElement.getAttribute("lat");
							longitude = eElement.getAttribute("lon");
							param4.put("idx", parentIndex);
							param4.put("latitude", latitude);
							param4.put("longitude", longitude);
							param4.put("xmlData", "");
							dataDao.updateVideo(param4);
						}
					}
	
					List<Map<String, String>> trkptList = new ArrayList<Map<String,String>>();
 					System.out.println("modifyNode.getNodeName() : " + modifyNode.getNodeName() + " // modifyNode.getChildNodes().getLength : " + modifyNode.getChildNodes().getLength());
					if(modifyNode != null && modifyNode.getChildNodes() != null && modifyNode.getChildNodes().getLength() >0 && ffmpegFileArr.size() > 0){
						int resTime = getVideoMaxTime(ffmpegFileArr);
						String makeResult = getTrkptForList(modifyNode.getChildNodes(), resTime, newXmlFilePathStr);
					}
					
				} //filesXml not null
			}else if(fileType != null && "worldFile".equals(fileType)){
				String idxArrStr = "";
				String[] idxArr = null;
				File fXmlSaveFile = null;
				Element eElement = null;
				boolean isSuccess = false;
				
				DocumentBuilderFactory dbf = DocumentBuilderFactory.newInstance();
				dbf.setIgnoringElementContentWhitespace(true);
				DocumentBuilder db = dbf.newDocumentBuilder();
				
				for(int j=0; j<fileItemList.size(); j++){
					item = fileItemList.get(j);
					tmpGpxFilePathDirFull = "";
					fileNameMap = new HashMap<String, Object>();
					fileMap = new HashMap<String, String>();
					newXmlFile = null;
					tmpPathStr = "";
					idxArrStr = "";
					idxArr = null;
					fXmlSaveFile = null;
					eElement = null;
					isSuccess = false;
					
					if(!item.isFormField() && files.get(j) != null) {
						fileMap = files.get(j);
						if(fileMap != null && fileMap.get("file") != null && fileMap.get("file") != ""){
							tmpGpxFilePathDirFull = fileMap.get("file");
//							tmpGpxFilePathDir = tmpGpxFilePathDirFull.substring(tmpGpxFilePathDirFull.lastIndexOf("\\")+1, tmpGpxFilePathDirFull.length());
							tmpGpxFilePathDir = tmpGpxFilePathDirFull.substring(tmpGpxFilePathDirFull.lastIndexOf(File.separator)+1, tmpGpxFilePathDirFull.length());
							
							item.write(new File(tmpGpxFilePathDirFull));
							item.delete();
							
							removeFileList.add(new File(tmpGpxFilePathDirFull));
							
							fis = new FileInputStream(tmpGpxFilePathDirFull);
							isSuccess = ftp.storeFile(tmpGpxFilePathDir, fis);
							
							if(isSuccess) {
								fXmlSaveFile = new File(tmpGpxFilePathDirFull);
								Document firstDoc = db.parse(fXmlSaveFile);
								NodeList nList1 = firstDoc.getElementsByTagName("trkpt");
								eElement = (Element)nList1.item(0);
								latitude = eElement.getAttribute("lat");
								longitude = eElement.getAttribute("lon");
								
								param4 = new HashMap<String, String>();
								param4.put("latitude", latitude);
								param4.put("longitude", longitude);
								
								idxArrStr = fileMap.get("idx");
								if(idxArrStr != null && !"".equals(idxArrStr)){
									idxArr = idxArrStr.split(",");
									if(idxArr != null && idxArr.length > 0){
										for(int m=0; m<idxArr.length; m++){
											param4.put("idx", idxArr[m]);
											param4.put("xmlData", "");
											dataDao.updateVideo(param4);
										    System.out.println(tmpGpxFilePathDirFull + "파일 FTP 업로드 성공");
										}
										////////////////////////////////////////////
										List<Map<String, String>> trkptList = new ArrayList<Map<String, String>>();
										if(nList1 != null && nList1.getLength() > 0){
											ffmpegFileArr = new ArrayList<String>();
											ffmpegFileArr = getIdxForFilePath(idxArr);
											if(ffmpegFileArr != null && ffmpegFileArr.size() > 0){
												int resTime = getVideoMaxTime(ffmpegFileArr);
												String makeResult = getTrkptForList(nList1, resTime, tmpGpxFilePathDirFull);
												System.out.println("makeResult : " +makeResult);
												if(makeResult != null && "success".equals(makeResult)){
													String makrFileRes = tmpGpxFilePathDirFull.substring(0, tmpGpxFilePathDirFull.lastIndexOf("."))+"_modify.gpx";
													removeFileList.add(new File(makrFileRes));
													fis = new FileInputStream(makrFileRes);
//													String makeFileFtp = makrFileRes.substring(makrFileRes.lastIndexOf("\\")+1, makrFileRes.length());
													String makeFileFtp = makrFileRes.substring(makrFileRes.lastIndexOf(File.separator)+1, makrFileRes.length());
													isSuccess = ftp.storeFile(makeFileFtp, fis);
													System.out.println("makrFileRes : " +makrFileRes + " makeFileFtp :" +makeFileFtp + " isSuccess :"+ isSuccess);
												}
											}
										}
									}//idx arr for end
								}
					       }
						}
						//FTP end---------------------------------------------------------------------------------------------------------
					}
				}
			}
		}catch(Exception e){
			e.printStackTrace();
			if(fileType != null && "videoFile".equals(fileType)){
				removeList = new ArrayList<Object>();
			    for(int m=0;m<files.size();m++){
			    	removeList.add(fileMap.get("idx"));
			    }
			    objParam.clear();
			    objParam.put("fileIdxs", removeList);
			    objParam.put("status", "ERROR");
			    dataDao.updateContentChildStatus(objParam);
			    
			    param2.clear();
			    param2.put("loginId", loginId);
			    param2.put("idx", String.valueOf(logKey));
			    param2.put("status", "ERROR");
			    dataDao.updateLog(param2);
			}
			fileType = null;
		}finally {
			if(fileType != null && "worldFile".equals(fileType) && removeFileList != null && removeFileList.size() > 0){
				for(int m=0;m<removeFileList.size();m++){
					removeFileList.get(m).delete();
				}
			}
		}
		
		if(fileType != null && "videoFile".equals(fileType)){
			EncodingController encodingController = new EncodingController(loginId, logKey, fileNameList, saveUserPath, serverUrlStr, userIdStr, userPassStr, portNumStr, saveFilePathStr);
			encodingController.setDataAPI(dataDao);
			encodingController.start();
		}
    }
	
	//nodeList to arraylist
	private String getTrkptForList(NodeList getNodeList, int resTime, String orgFileName) {
		List<Map<String, String>> resultList = new ArrayList<Map<String,String>>();
		Map<String, String> trkpMap = new HashMap<String, String>();
		String nLatStr = "";
		String nLonStr = "";
		Element nElement = null;
		String makeResult = "error";
		
		if(getNodeList != null && getNodeList.getLength() > 0){
			for(int n=0;n<getNodeList.getLength(); n++){
				if(getNodeList.item(n) != null && getNodeList.item(n).getNodeType() == 1){
					nLatStr = "";
					nLonStr = "";
					 nElement = (Element)getNodeList.item(n);
					if(nElement != null){
						trkpMap = new HashMap<String, String>();
						nLatStr = nElement.getAttribute("lat");
						nLonStr = nElement.getAttribute("lon");
						trkpMap.put("lat", nLatStr);
						trkpMap.put("lon", nLonStr);
						resultList.add(trkpMap);
					}
				}
			}
			
			if(resultList != null && resultList.size() > 0 && resTime > 0){
				makeResult = makeFileToList(resultList, resTime, orgFileName);
			}
		}
		
		return makeResult;
	}
	
	// file full path list to make max time
	private int getVideoMaxTime(List<String> gpxFilePathDirFullArr) {
		String osName = System.getProperty("os.name").toLowerCase();
		String osffmpeg = "";
		
		if(osName.indexOf("win") >= 0){
			osffmpeg = "win";
		}else if(osName.indexOf("mac") >= 0){
			osffmpeg = "mac";
		}else if(osName.indexOf("nix") >= 0 || osName.indexOf("nux") >= 0 || osName.indexOf("aix") > 0 ){
			osffmpeg = "linux";
		}else if(osName.indexOf("sunos") >= 0){
			osffmpeg = "sunos";
		}
		
		int resTime = 0;
		FFmpegSetting ffmpegSetting = new FFmpegSetting();
		String ffmpegPathStr = ffmpegSetting.getFfmpeg_dir_and_file_name();
		SimpleDateFormat sdf = new SimpleDateFormat("HH:mm:ss");
		FFmpeg ffmpeg = new FFmpeg();
		
		String tmpGpxFilePathDirFull = "";
		String[] message = null;
		String ffmpegNowFilePath = "";
		String ffmpegVal = "";
		String [] ffmpegTmpArr = null;
		String totalDurationStr = null;
		Date maxDate = null;
		Date nowDate = null;
		int compare = 0;
		
		try {
			if(gpxFilePathDirFullArr != null && gpxFilePathDirFullArr.size()>0){
				for(int i=0; i<gpxFilePathDirFullArr.size();i++){
					tmpGpxFilePathDirFull = gpxFilePathDirFullArr.get(i);
					message = null;
					ffmpegNowFilePath = "";
					ffmpegVal = "";
					ffmpegTmpArr = null;
					totalDurationStr = null;
					nowDate = null;
					compare = 0;
					
					if(tmpGpxFilePathDirFull != null && !"".equals(tmpGpxFilePathDirFull) && !"null".equals(tmpGpxFilePathDirFull)){
						if(osffmpeg != null && !"".equals(osffmpeg)){
							if("win".equals(osffmpeg))
							{
								message = new String[] {
										ffmpegPathStr,
										"-i",
										tmpGpxFilePathDirFull,
										"2>&1 | grep Duration | cut -d ' ' -f 4 | sed s/,//"
								};
								
								ffmpegNowFilePath = tmpGpxFilePathDirFull.substring(0,tmpGpxFilePathDirFull.lastIndexOf("\\"));
								ffmpegVal = ffmpeg.runFFmpeg(tmpGpxFilePathDirFull, ffmpegNowFilePath, message, "getTime");
							}else if("linux".equals(osffmpeg))
							{
								message = new String[] {
										"ffmpeg",
										"-i",
										tmpGpxFilePathDirFull,
										"2>&1 | grep Duration | cut -d ' ' -f 4 | sed s/,//"
								};
								
//								ffmpegNowFilePath = tmpGpxFilePathDirFull.substring(0,tmpGpxFilePathDirFull.lastIndexOf("\\"));
								ffmpegNowFilePath = tmpGpxFilePathDirFull.substring(0,tmpGpxFilePathDirFull.lastIndexOf(File.separator));
								ffmpegVal = ffmpeg.runFFmpeg_linux(tmpGpxFilePathDirFull, ffmpegNowFilePath, message, "getTime");
							}
						}
						System.out.println("ffmpegNowFilePath : " + ffmpegNowFilePath + " ffmpegVal : " + ffmpegVal);
						
						if(ffmpegVal != null && !"".equals(ffmpegVal) && !"null".equals(ffmpegVal)){
							ffmpegVal = ffmpegVal.split(",")[0];
							if(ffmpegVal != null && !"".equals(ffmpegVal) && !"null".equals(ffmpegVal)){
								ffmpegTmpArr = ffmpegVal.split(":");
								totalDurationStr = ffmpegTmpArr[1].trim() + ":"+ ffmpegTmpArr[2].trim() +":" + ffmpegTmpArr[3].trim();
								if(totalDurationStr != null && !"::".equals(totalDurationStr)){
									nowDate = sdf.parse(totalDurationStr);
									if(maxDate != null){
										compare = nowDate.compareTo(maxDate);
										if(compare > 0){
											maxDate = nowDate;
										}
									}else{
										maxDate = nowDate;
									}
								}
							}
						}
					}
				}
			}
			
			resTime = maxDate.getHours()*60*60;
			resTime += maxDate.getMinutes()*60;
			resTime += maxDate.getSeconds();
			
			System.out.println("종료 정보 resTime : "+ resTime);
		} catch (Exception e) {
			// TODO: handle exception
		}
		return resTime;
	}
	
	//video idx to filePath
	private List<String> getIdxForFilePath(String[] videoChildIdx){
		List<String> resList = new ArrayList<String>();
		List<Object> childList = new ArrayList<Object>();
		HashMap<String,String> childParam = new HashMap<String, String>();
		
		if(videoChildIdx != null && videoChildIdx.length > 0){
			for(int i=0; i< videoChildIdx.length;i++){
				String nowVideoIdx = videoChildIdx[i];
				if(nowVideoIdx != null && !"".equals(nowVideoIdx) && !"null".equals(nowVideoIdx)){
					childParam.put("parentIdx", nowVideoIdx);
					childList = dataDao.selectContentChildList(childParam);
					if(childList != null && childList.size() > 0){
						for(int j=0; j< childList.size();j++){
							childParam = new HashMap<String, String>();
							childParam = (HashMap)childList.get(j);
							if(childParam != null){
								String file_dir = "http://"+ serverUrlStr + "/shares/"+saveFilePathStr +"/GeoVideo/"+childParam.get("filename");
								System.out.println("file_dir = "+file_dir);
								File file = new File(saveUserPath);
								if(!file.exists()) file.mkdir();
								file = new File(saveUserPath+"/GeoVideo/"+ childParam.get("filename"));
								
								try {
									URL gamelan = new URL(file_dir);
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
						            FileUtils.copyURLToFile(gamelan, file);
								} catch (Exception e) {
									// TODO Auto-generated catch block
									e.printStackTrace();
									if(file.exists()){file.delete();}
								}
								
								resList.add(saveUserPath+ File.separator + "GeoVideo"+  File.separator + childParam.get("filename"));
							}
						}
					}
				}
			}
		}
		
		return resList;
	}
	
	// nodelist maxTime -> makeNew File
	private String makeFileToList(List<Map<String,String>> gpxList, int maxTimeInt, String orgFileName){
		System.out.println("makeFileToList ");
		int resInt = 0;
		List<Map<String,String>> resultList = new ArrayList<Map<String,String>>();
		Map<String,String> resultMap = new HashMap<String, String>();
		double lat1 = 0;
		double lon1 = 0;
		double lat2 = 0;
		double lon2 = 0;
		BigDecimal distance = new BigDecimal(0); 
		BigDecimal totalDistance = new BigDecimal(0); 
		List<BigDecimal> totalDistanceArr = new ArrayList<BigDecimal>();
		BigDecimal resDis = new BigDecimal(0);
		List<Double> angleArr = new ArrayList<Double>();
		BigDecimal maxTime = new BigDecimal(maxTimeInt);
		String makeResult = "error";
		
		if(gpxList != null && gpxList.size() > 1 && maxTimeInt > 1 ){
			if(gpxList.size() > maxTimeInt || gpxList.size() < maxTimeInt){
				for(int i=0; i<gpxList.size()-1; i++){
					lat1 = 0;
					lon1 = 0;
					lat2 = 0;
					lon2 = 0;
					distance = new BigDecimal(0); 
					
					if(gpxList.get(i).get("lat") != null && !"".equals(gpxList.get(i).get("lat")) && !"null".equals(gpxList.get(i).get("lat")) &&
							gpxList.get(i).get("lon") != null && !"".equals(gpxList.get(i).get("lon")) && !"null".equals(gpxList.get(i).get("lon")) &&
							gpxList.get(i+1).get("lat") != null && !"".equals(gpxList.get(i+1).get("lat")) && !"null".equals(gpxList.get(i+1).get("lat")) &&
							gpxList.get(i+1).get("lon") != null && !"".equals(gpxList.get(i+1).get("lon")) && !"null".equals(gpxList.get(i+1).get("lon"))){
						lat1 = Double.parseDouble(gpxList.get(i).get("lat"));
						lon1 = Double.parseDouble(gpxList.get(i).get("lon"));
						lat2 = Double.parseDouble(gpxList.get(i+1).get("lat"));
						lon2 = Double.parseDouble(gpxList.get(i+1).get("lon"));
						distance = getDistance(lat1, lon1, lat2, lon2);
						totalDistance = totalDistance.add(distance);
						totalDistanceArr.add(totalDistance);
						angleArr.add(getAngel(lat1, lon1, lat2, lon2));
					}
				}//end for
				
				resDis = (totalDistance.divide(maxTime,13, BigDecimal.ROUND_HALF_UP));
				System.out.println("resDis :  " + resDis);
				
				double xa = 0;
				double ya = 0;
				BigDecimal disa = new BigDecimal(0);
				BigDecimal disa2 = new BigDecimal(0);
				int arrCnt = 0;
				for(int i=0; i<maxTimeInt; i++){
					disa2 = new BigDecimal(0);
					resultMap = new HashMap<String, String>();
					if(i == 0){
						resultMap.put("lat", gpxList.get(i).get("lat"));
						resultMap.put("lon", gpxList.get(i).get("lon"));
					}else if(i == maxTimeInt-1){
						resultMap.put("lat", gpxList.get(gpxList.size()-1).get("lat"));
						resultMap.put("lon", gpxList.get(gpxList.size()-1).get("lon"));
					}else{
						if(i == 1){
							xa = Double.valueOf(gpxList.get(0).get("lat"));
							ya = Double.valueOf(gpxList.get(0).get("lon"));
						}
						disa = disa.add(resDis);
						if(disa.compareTo(totalDistanceArr.get(arrCnt)) == 1){
							BigDecimal tmpDisa = disa;
							for(int j=arrCnt+1;j<totalDistanceArr.size();j++){
								System.out.println("tmpDisa : " + tmpDisa + " totalDistanceArr : " + totalDistanceArr.get(j) + " : " + j);
								if(tmpDisa.compareTo(totalDistanceArr.get(j)) == 1){
//									tmpDisa = tmpDisa.add(resDis);
								}else{
									disa2 = tmpDisa.subtract(totalDistanceArr.get(j-1));
//									disa = disa2;
									arrCnt = j;
									xa = Double.valueOf(gpxList.get(arrCnt).get("lat"));
									ya = Double.valueOf(gpxList.get(arrCnt).get("lon"));
									break;
								}
							}
						}else{
							if(arrCnt > 0){
								disa2 = disa.subtract(totalDistanceArr.get(arrCnt-1));
							}else{
								disa2 = disa;
							}
						}
						
						List<Double> resDouble = getNowPosition(xa, ya, disa2, angleArr.get(arrCnt));
						resultMap.put("lat", String.valueOf(resDouble.get(0)));
						resultMap.put("lon", String.valueOf(resDouble.get(1)));
					}
					resultList.add(resultMap);
				}
				
				DocumentBuilderFactory dbf = DocumentBuilderFactory.newInstance();
				dbf.setIgnoringElementContentWhitespace(true);
				
				try {
					DocumentBuilder db = dbf.newDocumentBuilder();
					String newXmlFilePathStr = orgFileName;
					File fXmlSaveFile = new File(newXmlFilePathStr);
					Document firstDoc = db.parse(fXmlSaveFile);
					Node results = firstDoc.getElementsByTagName("trkseg").item(0);
					while(results.hasChildNodes()){
						Node kid = results.getFirstChild();
				        results.removeChild(kid);
					}
					
					for(int z=0;z<resultList.size();z++){
						Element e = firstDoc.createElement("trkpt");
						e.setAttribute("lat", resultList.get(z).get("lat"));
						e.setAttribute("lon", resultList.get(z).get("lon"));
						results.appendChild(e);
					}
					Node gpxNode = firstDoc.getElementsByTagName("gpx").item(0);
			    	Node trkNode = firstDoc.getElementsByTagName("trk").item(0);
			    	
				    trkNode.appendChild(results);
				    gpxNode.appendChild(trkNode);
				    firstDoc.importNode(gpxNode, true);
				    
					TransformerFactory transformerFactory = TransformerFactory.newInstance();
				    Transformer transformer = transformerFactory.newTransformer();
				    DOMSource source = new DOMSource(gpxNode);
				    Result result = new StreamResult(new File(newXmlFilePathStr.substring(0, newXmlFilePathStr.lastIndexOf(".")) + "_modify.gpx"));
				    transformer.transform(source, result);
		        	
				} catch (Exception e) {
					// TODO Auto-generated catch block
					e.printStackTrace();
				}
			}
			makeResult = "success";
		}
		return makeResult;
	}
	
	private BigDecimal getDistance(double x, double y, double x1, double y1) {
		double resultDouble = (double)Math.sqrt(Math.pow(Math.abs(x1-x), 2)+ Math.pow(Math.abs(y1-y), 2)); //7.087060472661628E-4
		double b = (double)Math.sqrt((x-x1)*(x-x1)+(y-y1)*(y-y1)); //7.087060472661628E-4
		
		BigDecimal bigVal = new BigDecimal(resultDouble);
		return bigVal;
	}
	
	private double getAngel(double x, double y, double x1, double y1) {
		double dx = x1 - x;
		double dy = y1 - y;
		return Math.toDegrees(Math.atan2(dy, dx));
	}
	
	private List<Double> getNowPosition(double x, double y, BigDecimal distance, double angel) {
		List<Double> resArr = new ArrayList<Double>();
		double ag = angel*Math.PI/180;
		
		double distanceDouble = distance.doubleValue();
		double x2 = x + distanceDouble * Math.cos(ag);
		double y2 = y + distanceDouble * Math.sin(ag);
		resArr.add(x2);
		resArr.add(y2);
		return resArr;
	}
	
}
