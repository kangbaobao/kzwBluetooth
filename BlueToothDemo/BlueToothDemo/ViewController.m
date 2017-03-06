//
//  ViewController.m
//  BlueToothDemo
//
//  Created by uhut on 16/1/15.
//  Copyright © 2016年 KZW. All rights reserved.
//

#import "ViewController.h"
static NSString * const kServiceUUID = @"4F7A8581-C547-474B-8696-D8ACFD543AD0";

static NSString * const kCharacteristicUUID = @"483407AC-A05C-4289-8240-F3E02A4F1CB8";
@interface ViewController ()<UITextFieldDelegate>
@property (nonatomic, strong) CBPeripheralManager *manager;
@property(nonatomic,strong)CBMutableCharacteristic *customCharacteristic;
@property(nonatomic,strong)CBMutableService *customService;
@property (weak, nonatomic) IBOutlet UILabel *label;
@property (weak, nonatomic) IBOutlet UITextField *tesfiled;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.manager = [[CBPeripheralManager alloc] initWithDelegate:self queue:nil];
}

#pragma mark testfiled
-(BOOL)textFieldShouldReturn:(UITextField *)textField{
    [self.tesfiled resignFirstResponder];
    [self update];
    return YES;
}
-(void)update{
    NSString *str=_tesfiled.text;//@"我去终于成功了";
    NSData *data=[str dataUsingEncoding:NSUTF8StringEncoding];
    _label.text=@"str";
    //向其他设备发送消息
    [self.manager updateValue:data forCharacteristic:self.customCharacteristic onSubscribedCentrals:nil];
}
#pragma mark  创建蓝牙服务
-(void)setupService{
    // Creates the characteristic UUID
    CBUUID *characteristicUUID = [CBUUID UUIDWithString:kCharacteristicUUID];
    // Creates the characteristic
    
    /*最后一个参数是属性的读、写、加密的权限，可能的值是以下的：
     ■CBAttributePermissionsReadable
     ■CBAttributePermissionsWriteable
     ■CBAttributePermissionsReadEncryptionRequired
     ■CBAttributePermissionsWriteEncryptionRequired
     */
    self.customCharacteristic = [[CBMutableCharacteristic alloc] initWithType:
                                 characteristicUUID properties:CBCharacteristicPropertyNotify
                                                                        value:nil permissions:CBAttributePermissionsReadable];
    // Creates the service UUID
    CBUUID *serviceUUID = [CBUUID UUIDWithString:kServiceUUID];
    // Creates the service and adds the characteristic to it
    self.customService = [[CBMutableService alloc] initWithType:serviceUUID
                                                        primary:YES];
    // Sets the characteristics for this service
    [self.customService setCharacteristics:
  @[self.customCharacteristic]];
    
    // Publishes the service
    [self.manager addService:self.customService];
}

#pragma mark  CBPeripheralManagerDelegate
#pragma mark  检测蓝牙状态改变
- (void)peripheralManagerDidUpdateState:(CBPeripheralManager *)peripheral
{
    /*CBPeripheralManagerStateUnknown = 0,
     CBPeripheralManagerStateResetting,
     CBPeripheralManagerStateUnsupported,
     CBPeripheralManagerStateUnauthorized,
     CBPeripheralManagerStatePoweredOff,
     CBPeripheralManagerStatePoweredOn,*/
    switch (peripheral.state) {
        case CBCentralManagerStatePoweredOn:
        {
//            [self.manager  scanForPeripheralsWithServices:nil options:@{CBCentralManagerScanOptionAllowDuplicatesKey:@(YES)}];
            [self setupService];
            _label.text=@"蓝牙已经打开，请扫描外设,请打开外围设备";
            NSLog(@"蓝牙已经打开，请扫描外设,请打开外围设备");
            break;
        }
        case CBCentralManagerStatePoweredOff:
        {
//            _connectionSuccess = EquiomentConnectionFiale;
//            [self disconnect];
            _label.text=@"蓝牙已关闭，请开启外设";

            NSLog(@"蓝牙已关闭，请开启外设");
            break;
        }
        case CBCentralManagerStateResetting:
        {
            _label.text=@"重置中心设别";

            NSLog(@"重置中心设别");
            break;
        }
        case CBCentralManagerStateUnauthorized:
        {
            _label.text=@"授权中心设备";

            NSLog(@"授权中心设备");
            break;
        }
        case CBCentralManagerStateUnknown:
        {
            _label.text=@"中心设备状态未知";

            NSLog(@"中心设备状态未知");
            break;
        }
        case CBCentralManagerStateUnsupported:
        {
            _label.text=@"不支持中心设备";

            NSLog(@"不支持中心设备");
            break;
        }
        default:
            break;
    }
}
#pragma mark  添加服务完成 服务添加到周边管理者（Peripheral Manager）是用于发布服务。一旦完成这个，周边管理者会通知他的代理方法-peripheralManager:didAddService:error:。现在，如果没有Error，你可以开始广播服务了
- (void)peripheralManager:(CBPeripheralManager *)peripheral
            didAddService:(CBService *)service error:(NSError *)error {
    if (error == nil) {
        _label.text=@"添加服务完成";

        // Starts advertising the service
        [self.manager startAdvertising:
  @{ CBAdvertisementDataLocalNameKey :
         @"ICServer", CBAdvertisementDataServiceUUIDsKey :
         @[[CBUUID UUIDWithString:kServiceUUID]] }];
    }
}
//开始广播服务
-(void)peripheralManagerDidStartAdvertising:(CBPeripheralManager *)peripheral error:(NSError *)error{
    if(error){
       _label.text=[error localizedDescription];
        NSLog(@" peripheralManagerDidStartAdvertising,error==%@",error);
    }else{
    _label.text=@"开始广播服务";
      
    }

    
}
//中央预定了这个服务 接收消息 开始发送数据
-(void)peripheralManager:(CBPeripheralManager *)peripheral central:(CBCentral *)central didSubscribeToCharacteristic:(CBCharacteristic *)characteristic{
    [self update];
   
}
//失去连接
-(void)peripheralManager:(CBPeripheralManager *)peripheral central:(CBCentral *)central didUnsubscribeFromCharacteristic:(CBCharacteristic *)characteristic{
    _label.text=@"失去连接";

}
@end
