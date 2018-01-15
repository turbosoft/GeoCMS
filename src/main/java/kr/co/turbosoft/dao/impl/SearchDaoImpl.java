package kr.co.turbosoft.dao.impl;

import java.util.HashMap;
import java.util.List;

import org.mybatis.spring.support.SqlSessionDaoSupport;

import kr.co.turbosoft.dao.SearchDao;


public class SearchDaoImpl extends SqlSessionDaoSupport implements SearchDao {
	private HashMap<String, String> result;
	private List<Object> resultList;
	private int resultIntegerValue;
	private String resultStringValue;
	
	@Override
	public List<Object> selectSearchList(HashMap<String, String> param) {
		// TODO Auto-generated method stub
		resultList = getSqlSession().selectList("search.selectSearchList", param);
		
		return resultList;
	}
}
