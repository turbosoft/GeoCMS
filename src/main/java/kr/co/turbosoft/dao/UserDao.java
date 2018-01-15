package kr.co.turbosoft.dao;

import java.util.HashMap;
import java.util.List;

public interface UserDao {
	public int insertUser(HashMap<String, String> param);
	public int updateUser(HashMap<String, String> param);
	public HashMap<String, String> selectUser(HashMap<String, String> param);
	public HashMap<String, String> selectUid(HashMap<String, String> param);
	public List<Object> selectAllUser(HashMap<String, String> param);
	public HashMap<String, String> selectAllUserLen(HashMap<String, String> param);
	
	public int insertToken(HashMap<String, String> param);
	public int updateToken(HashMap<String, String> param);
	public int updateTokenTime(HashMap<String, String> param);
	
	public List<Object> selectShareUser(HashMap<String, Object> param);
	public HashMap<String, String> selectShareUserLen(HashMap<String, Object> param);
	
	public int insertShare(HashMap<String, Object> param);
	public int deleteShare(HashMap<String, Object> param);
	
	public List<Object> selectShareUserList(HashMap<String, String> param);
	public int updateShareEdit(HashMap<String, Object> param);
	
	public int insertShareFormProject(HashMap<String, String> param);
}
