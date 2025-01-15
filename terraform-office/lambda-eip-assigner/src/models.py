from typing import TypedDict, List

class EventDetails(TypedDict):
    Subnet_ID: str
    Availability_Zone: str

class Detail(TypedDict):
    Origin: str
    Destination: str
    Description: str
    EndTime: str
    RequestId: str
    ActivityId: str
    StartTime: str
    EC2InstanceId: str
    StatusCode: str
    StatusMessage: str
    Details: EventDetails
    Cause: str
    AutoScalingGroupName: str

class EventBridgeEvent(TypedDict):
    version: str
    id: str
    detail_type: str
    source: str
    account: str
    time: str
    region: str
    resources: List[str]
    detail: Detail