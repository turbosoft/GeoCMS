package kr.co.turbosoft.dao;

import java.util.HashMap;
import java.util.List;

public interface DataDao {
//	public void thisRollback();
//	public void thisConnection();
//	public void thisCommit();
//	public void thisClose();

	public List<Object> selectBase();
	public int updateBase(HashMap<String, String> param);
	
	public List<Object> selectTabList(HashMap<String, Object> param);
	public int insertTab(HashMap<String, String> param);
	public int updateTab(HashMap<String, String> param);
	public int deleteTab(HashMap<String, Object> param);
	
	public int updateTabIdxBoard(HashMap<String, String> param);
	public int updateTabBoardIdx(HashMap<String, Object> param);
	public int updateTabIdxProject(HashMap<String, String> param);
	public int updateTabProjectIdx(HashMap<String, Object> param);
	
	public List<Object> selectBoardList(HashMap<String, String> param);
	public HashMap<String, String> selectBoardListLen(HashMap<String, String> param);
	public int insertBoard(HashMap<String, String> param);
	public int updateBoard(HashMap<String, String> param);
	public int deleteBoard(HashMap<String, String> param);
	
	public List<Object> selectAllContentList(HashMap<String, Object> param);
	public List<Object> selectContentList(HashMap<String, String> param);
	public HashMap<String, String> selectContentListLen(HashMap<String, String> param);
	
	public List<Object> selectImageList(HashMap<String, String> param);
	public HashMap<String, String> selectImageListLen(HashMap<String, String> param);
	public int insertImage(HashMap<String, Object> param);
	public int updateImage(HashMap<String, String> param);
	public int deleteImage(HashMap<String, String> param);
	public int updateXmlData(HashMap<String, String> param);
	public int updateImageMove(HashMap<String, String> param);
	
	public List<Object> selectVideoList(HashMap<String, String> param);
	public HashMap<String, String> selectVideoListLen(HashMap<String, String> param);
	public int insertVideo(HashMap<String, String> param);
	public int updateVideo(HashMap<String, String> param);
	public int deleteVideo(HashMap<String, String> param);
	public int updateVideoMove(HashMap<String, String> param);
	
	public List<Object> selectAllProjectList(HashMap<String, String> param);
	public List<Object> selectProjectList(HashMap<String, String> param);
	public List<Object> selectProjectContentList(HashMap<String, String> param);
	public HashMap<String, String> selectProjectContentListLen(HashMap<String, String> param);
	public HashMap<String, String> selectProjectMaxSeq(HashMap<String, String> param);
	public int insertProject(HashMap<String, String> param);
	public int updateProject(HashMap<String, String> param);
	public int deleteProject(HashMap<String, String> param);
	
	public List<Object> selectMarkerList();
	
	public List<Object> selectContentLogList(HashMap<String, String> param);
	public int insertLog(HashMap<String, String> param);
	public int updateLog(HashMap<String, String> param);
	
	public List<Object> selectContentChildList(HashMap<String, String> param);
	public int insertChildContent(HashMap<String, Object> param);
	public int insertChildContentFromParent(HashMap<String, Object> param);
	public int deleteContentChild(HashMap<String, String> param);
	
	public List<Object> selectImageFileList(HashMap<String, String> param);
	public List<Object> selectVideoFileList(HashMap<String, String> param);
	
	public int updateImageStatus(HashMap<String, Object> param);
	public int updateContentChildStatus(HashMap<String, Object> param);
}
