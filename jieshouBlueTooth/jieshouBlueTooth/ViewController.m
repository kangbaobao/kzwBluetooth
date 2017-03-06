//
//  ViewController.m
//  jieshouBlueTooth
//
//  Created by uhut on 16/1/15.
//  Copyright © 2016年 KZW. All rights reserved.
//

#import "ViewController.h"
static NSString * const kServiceUUID = @"4F7A8581-C547-474B-8696-D8ACFD543AD0";

static NSString * const kCharacteristicUUID = @"483407AC-A05C-4289-8240-F3E02A4F1CB8";

@interface ViewController ()<CBCentralManagerDelegate,
CBPeripheralDelegate>
@property (nonatomic, strong) CBCentralManager *manager;
@property (nonatomic, strong) NSMutableData *data;


@property(nonatomic,strong)CBPeripheral *peripheral;
@property (weak, nonatomic) IBOutlet UILabel *label;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.data=[NSMutableData dataWithCapacity:0];
    self.manager = [[CBCentralManager alloc] initWithDelegate:self queue:nil];

}
#pragma mark  CBCentralManagerDelegate
-(void)centralManagerDidUpdateState:(CBCentralManager *)central{
    switch (central.state) {
        case CBCentralManagerStatePoweredOn:
            self.label.text=@"蓝牙已打开";

            /*-scanForPeripheralsWithServices:options: 方法是用于告诉Central Manager，要开始寻找一个指定的服务了。如果你将第一个参数设置为nil，Central Manager就会开始寻找所有的服务。*/
            // Scans for any peripheral
            [self.manager scanForPeripheralsWithServices:
      @[ [CBUUID UUIDWithString:kServiceUUID] ]
                                                 options:@{CBCentralManagerScanOptionAllowDuplicatesKey :
                                                               @YES }];
            break;
        default:
            self.label.text=@"蓝牙关闭";
            NSLog(@"Central Manager did change state");
            break;
    }

}
#pragma mark  搜索到可用蓝牙信号, 知道了信号质量，你可以用它去判断远近。 任何广播、扫描的响应数据保存在advertisementData 中，可以通过CBAdvertisementData 来访问它。现在，你可以停止扫描，而去连接周边了：
- (void)centralManager:(CBCentralManager *)central
 didDiscoverPeripheral:(CBPeripheral *)peripheral
     advertisementData:(NSDictionary *)advertisementData
                  RSSI:(NSNumber *)RSSI {
    self.label.text=@"搜索到可用蓝牙信号";

    // Stops scanning for peripheral 停止信号扫描
    [self.manager stopScan];
    if (self.peripheral != peripheral) {
        self.peripheral = peripheral;
        NSLog(@"Connecting to peripheral %@", peripheral);
        // Connects to the discovered peripheral  连接周边了
        [self.manager connectPeripheral:peripheral options:nil];
    }
}
#pragma mark 连接蓝牙失败
-(void)centralManager:(CBCentralManager *)central didFailToConnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error{
    self.label.text=@"连接蓝牙失败";

    NSLog(@"连接蓝牙失败");
}
#pragma mark 连接蓝牙成功
- (void)centralManager:(CBCentralManager *)central
  didConnectPeripheral:(CBPeripheral *)peripheral {
    // Clears the data that we may already have
    [self.data setLength:0];
    // Sets the peripheral delegate
    [self.peripheral setDelegate:self];
    self.label.text=@"请求周边去寻找服务,调用 discoverServices 会走CBPeripheralDelegate代理";

    // Asks the peripheral to discover the service 请求周边去寻找服务,调用 discoverServices 会走CBPeripheralDelegate代理
    [self.peripheral discoverServices:
  @[ [CBUUID UUIDWithString:kServiceUUID] ]];
}
#pragma mark  CBPeripheralDelegate
//请求周边去寻找服务，周边代理接收-peripheral:didDiscoverServices:。如果没有Error，可以请求周边去寻找它的服务所列出的特征，像以下这么做
-(void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error{
    if (error) {
        NSLog(@"Error discovering service:%@", [error localizedDescription]);
//              [self cleanup];
        self.label.text=error.localizedDescription;

              return;
              }
              for (CBService *service in peripheral.services) {
                  NSLog(@"Service found with UUID: %@",
                        service.UUID);
                  // Discovers the characteristics for a given service uuid相同，发送链接
                  if ([service.UUID isEqual:[CBUUID
                                             UUIDWithString:kServiceUUID]]) {
                      self.label.text=@"发送链接";

                      [self.peripheral discoverCharacteristics: @[[CBUUID UUIDWithString: kCharacteristicUUID]] forService:service];//
                  }
              }
}
//，如果一个特征被发现，周边代理会接收
- (void)peripheral:(CBPeripheral *)peripheral
didDiscoverCharacteristicsForService:
(CBService *)service error:(NSError *)error {
    if (error) {
        NSLog(@"Error discovering characteristic:%@", [error localizedDescription]);
//              [self cleanup];
        self.label.text=error.localizedDescription;

              return;
              }
              if ([service.UUID isEqual:[CBUUID UUIDWithString:
                                         kServiceUUID]]) {
            for (CBCharacteristic *characteristic in
                 service.characteristics) {
                if ([characteristic.UUID isEqual:[CBUUID
                                                  UUIDWithString:kCharacteristicUUID]]) {
                    //一旦特征的值被更新，用-setNotifyValue:forCharacteristic:，周边被请求通知它的代理。
                    [peripheral setNotifyValue:YES 
                             forCharacteristic:characteristic];
                }
            }
        }
 }

//如果一个特征的值被更新，然后周边代理接收
- (void)peripheral:(CBPeripheral *)peripheral
didUpdateNotificationStateForCharacteristic:
(CBCharacteristic *)characteristic error:(NSError *)error {
    if (error) {
        NSLog(@"Error changing notification state:%@", error.localizedDescription);
        self.label.text=error.localizedDescription;

              }
              // Exits if it's not the transfer characteristic
              if (![characteristic.UUID isEqual:[CBUUID
                                                 UUIDWithString:kCharacteristicUUID]]) {
            return;
        }
              // Notification has started
              if (characteristic.isNotifying) {
                  NSLog(@"Notification began on %@", characteristic);
                  [peripheral readValueForCharacteristic:characteristic];
                }else{
                    // Notification has stopped
                  // so disconnect from the peripheral
                  NSLog(@"Notification stopped on %@.Disconnecting", characteristic);
                  self.label.text=characteristic.description;

                        [self.manager cancelPeripheralConnection:self.peripheral];
                        }
}
#pragma mark  接受到数据
-(void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error{
    if (error) {
        NSLog(@"错误：==  %@",error);
        self.label.text=[error localizedDescription];

//        return;
    }
    NSData * Mydata= characteristic.value;
    NSString *str=[[NSString alloc] initWithData:Mydata encoding:NSUTF8StringEncoding];
    NSLog(@"str==%@  Mydata==%@",str,Mydata);
    self.label.text=str;

}
@end
