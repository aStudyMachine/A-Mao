package cn.studymachine.system.satoken;

import cn.studymachine.user.api.UserPermFacade;
import cn.studymachine.user.api.dto.UserPermDTO;
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
 * system 侧 StpInterface：UserPermFacade 解包与失败空安全。
 */
@ExtendWith(MockitoExtension.class)
class StpInterfaceImplTest {

    @Mock
    private UserPermFacade userPermFacade;

    @InjectMocks
    private StpInterfaceImpl stpInterface;

    @Test
    void roles_fromFacade() {
        UserPermDTO dto = new UserPermDTO();
        dto.setUserId(1L);
        dto.setRoles(List.of("admin"));
        dto.setPermissions(List.of("sys:dict:list"));
        when(userPermFacade.getUserPerm(1L)).thenReturn(dto);

        assertEquals(List.of("admin"), stpInterface.getRoleList(1L, "login"));
        assertEquals(List.of("sys:dict:list"), stpInterface.getPermissionList(1L, "login"));
    }

    @Test
    void nullDto_emptyLists() {
        when(userPermFacade.getUserPerm(1L)).thenReturn(null);
        assertTrue(stpInterface.getRoleList(1L, "login").isEmpty());
        assertTrue(stpInterface.getPermissionList(1L, "login").isEmpty());
    }

    @Test
    void facadeError_emptyLists() {
        when(userPermFacade.getUserPerm(1L)).thenThrow(new RuntimeException("rpc down"));
        assertTrue(stpInterface.getRoleList(1L, "login").isEmpty());
        assertTrue(stpInterface.getPermissionList(1L, "login").isEmpty());
    }
}
