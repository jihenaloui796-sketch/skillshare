package com.skillshare.dto.request;

import com.skillshare.model.RequestStatus;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;
import lombok.Data;

@Data
public class RequestUpdateRequest {

    @NotNull
    private RequestStatus status;

    @Size(max = 2000)
    private String message;
}
