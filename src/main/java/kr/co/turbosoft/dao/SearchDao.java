package kr.co.turbosoft.dao;

import java.util.HashMap;
import java.util.List;

public interface SearchDao {
	public List<Object> selectSearchList(HashMap<String, String> param);//검색 리스트 요청
}
