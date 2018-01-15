package kr.co.turbosoft.dao.impl;

import java.util.HashMap;
import java.util.List;

import org.mybatis.spring.support.SqlSessionDaoSupport;

import kr.co.turbosoft.dao.UserDao;

public class UserDaoImpl extends SqlSessionDaoSupport implements UserDao{
	private HashMap<String, String> result;
	private List<Object> resultList;
	private int resultIntegerValue;
	private String resultStringValue;
	
	@Override
	public int insertUser(HashMap<String, String> param) {
		// TODO Auto-generated method stub
		
		resultIntegerValue = getSqlSession().insert("user.insertUser", param);
		
		return resultIntegerValue;
	}
	
	@Override
	public int updateUser(HashMap<String, String> param) {
		// TODO Auto-generated method stub
		
		resultIntegerValue = getSqlSession().update("user.updateUser", param);
		
		return resultIntegerValue;
	}
	
	@Override
	public HashMap<String, String> selectUser(HashMap<String, String> param) {
		// TODO Auto-generated method stub
		result = (HashMap<String, String>) getSqlSession().selectOne("user.selectUser", param);
		
		return result;
	}
	
	@Override
	public HashMap<String, String> selectUid(HashMap<String, String> param) {
		// TODO Auto-generated method stub
		
		result = getSqlSession().selectOne("user.selectUid", param);
		
		return result;
	}
	
	@Override
	public List<Object> selectAllUser(HashMap<String, String> param) {
		// TODO Auto-generated method stub
		resultList = getSqlSession().selectList("user.selectAllUser", param);
		
		return resultList;
	}
	
	@Override
	public HashMap<String, String> selectAllUserLen(HashMap<String, String> param) {
		// TODO Auto-generated method stub
		
		result = getSqlSession().selectOne("user.selectAllUserLen", param);
		
		return result;
	}
	
	@Override
	public int insertToken(HashMap<String, String> param) {
		// TODO Auto-generated method stub
		
		resultIntegerValue = getSqlSession().insert("user.insertToken", param);
		
		return resultIntegerValue;
	}
	
	@Override
	public int updateToken(HashMap<String, String> param) {
		// TODO Auto-generated method stub
		
		resultIntegerValue = getSqlSession().update("user.updateToken", param);
		
		return resultIntegerValue;
	}
	
	@Override
	public int updateTokenTime(HashMap<String, String> param) {
		// TODO Auto-generated method stub
		
		resultIntegerValue = getSqlSession().update("user.updateTokenTime", param);
		
		return resultIntegerValue;
	}
	
	@Override
	public List<Object> selectShareUser(HashMap<String, Object> param) {
		// TODO Auto-generated method stub
		resultList = getSqlSession().selectList("user.selectShareUser", param);
		
		return resultList;
	}
	
	@Override
	public HashMap<String, String> selectShareUserLen(HashMap<String, Object> param) {
		// TODO Auto-generated method stub
		
		result = getSqlSession().selectOne("user.selectShareUserLen", param);
		
		return result;
	}
	
	@Override
	public int insertShare(HashMap<String, Object> param) {
		// TODO Auto-generated method stub
		
		resultIntegerValue = getSqlSession().insert("user.insertShare", param);
		
		return resultIntegerValue;
	}
	
	@Override
	public int deleteShare(HashMap<String, Object> param) {
		// TODO Auto-generated method stub
		
		resultIntegerValue = getSqlSession().delete("user.deleteShare", param);
		
		return resultIntegerValue;
	}
	
	@Override
	public List<Object> selectShareUserList(HashMap<String, String> param) {
		// TODO Auto-generated method stub
		resultList = getSqlSession().selectList("user.selectShareUserList", param);
		
		return resultList;
	}
	
	@Override
	public int updateShareEdit(HashMap<String, Object> param) {
		// TODO Auto-generated method stub
		
		resultIntegerValue = getSqlSession().update("user.updateShareEdit", param);
		
		return resultIntegerValue;
	}
	
	@Override
	public int insertShareFormProject(HashMap<String, String> param) {
		// TODO Auto-generated method stub
		
		resultIntegerValue = getSqlSession().insert("user.insertShareFormProject", param);
		
		return resultIntegerValue;
	}
}
