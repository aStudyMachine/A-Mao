package cn.studymachine.user.satoken;

import cn.studymachine.user.mapper.SysRoleMapper;
import cn.studymachine.user.mapper.SysRolePermissionMapper;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.util.List;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertTrue;
import static org.mockito.Mockito.when;

/**
 * user 侧 StpInterface 聚合与空安全。
 */
@ExtendWith(MockitoExtension.class)
class StpInterfaceImplTest {

    @Mock
    private SysRoleMapper sysRoleMapper;

    @Mock
    private SysRolePermissionMapper sysRolePermissionMapper;

    @InjectMocks
    private StpInterfaceImpl stpInterface;

    @Test
    void getRoleList_dedupedBySql() {
        when(sysRoleMapper.selectRoleNamesByUserId(1L)).thenReturn(List.of("admin", "ops"));
        assertEquals(List.of("admin", "ops"), stpInterface.getRoleList(1L, "login"));
    }

    @Test
    void getPermissionList_emptySafe() {
        when(sysRolePermissionMapper.selectPermissionsByUserId(1L)).thenReturn(null);
        assertTrue(stpInterface.getPermissionList(1L, "login").isEmpty());
    }

    @Test
    void getPermissionList_returnsDistinct() {
        when(sysRolePermissionMapper.selectPermissionsByUserId(1L))
                .thenReturn(List.of("sys:dict:list"));
        assertEquals(List.of("sys:dict:list"), stpInterface.getPermissionList(1L, "login"));
    }
}
