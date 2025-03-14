// Code generated by protoc-gen-go-grpc. DO NOT EDIT.
// versions:
// - protoc-gen-go-grpc v1.2.0
// - protoc             v4.25.3
// source: searcher.proto

package api

import (
	context "context"
	grpc "google.golang.org/grpc"
	codes "google.golang.org/grpc/codes"
	status "google.golang.org/grpc/status"
	emptypb "google.golang.org/protobuf/types/known/emptypb"
)

// This is a compile-time assertion to ensure that this generated file
// is compatible with the grpc package it is being compiled against.
// Requires gRPC-Go v1.32.0 or later.
const _ = grpc.SupportPackageIsVersion7

// SearcherClient is the client API for Searcher service.
//
// For semantics around ctx use and closing/ending streaming RPCs, please refer to https://pkg.go.dev/google.golang.org/grpc/?tab=doc#ClientConn.NewStream.
type SearcherClient interface {
	GetScore(ctx context.Context, in *GetScoreRequest, opts ...grpc.CallOption) (*Score, error)
	GetScores(ctx context.Context, in *GetScoresRequest, opts ...grpc.CallOption) (Searcher_GetScoresClient, error)
	GetFavourites(ctx context.Context, in *emptypb.Empty, opts ...grpc.CallOption) (Searcher_GetFavouritesClient, error)
}

type searcherClient struct {
	cc grpc.ClientConnInterface
}

func NewSearcherClient(cc grpc.ClientConnInterface) SearcherClient {
	return &searcherClient{cc}
}

func (c *searcherClient) GetScore(ctx context.Context, in *GetScoreRequest, opts ...grpc.CallOption) (*Score, error) {
	out := new(Score)
	err := c.cc.Invoke(ctx, "/score.Searcher/GetScore", in, out, opts...)
	if err != nil {
		return nil, err
	}
	return out, nil
}

func (c *searcherClient) GetScores(ctx context.Context, in *GetScoresRequest, opts ...grpc.CallOption) (Searcher_GetScoresClient, error) {
	stream, err := c.cc.NewStream(ctx, &Searcher_ServiceDesc.Streams[0], "/score.Searcher/GetScores", opts...)
	if err != nil {
		return nil, err
	}
	x := &searcherGetScoresClient{stream}
	if err := x.ClientStream.SendMsg(in); err != nil {
		return nil, err
	}
	if err := x.ClientStream.CloseSend(); err != nil {
		return nil, err
	}
	return x, nil
}

type Searcher_GetScoresClient interface {
	Recv() (*ScoresPage, error)
	grpc.ClientStream
}

type searcherGetScoresClient struct {
	grpc.ClientStream
}

func (x *searcherGetScoresClient) Recv() (*ScoresPage, error) {
	m := new(ScoresPage)
	if err := x.ClientStream.RecvMsg(m); err != nil {
		return nil, err
	}
	return m, nil
}

func (c *searcherClient) GetFavourites(ctx context.Context, in *emptypb.Empty, opts ...grpc.CallOption) (Searcher_GetFavouritesClient, error) {
	stream, err := c.cc.NewStream(ctx, &Searcher_ServiceDesc.Streams[1], "/score.Searcher/GetFavourites", opts...)
	if err != nil {
		return nil, err
	}
	x := &searcherGetFavouritesClient{stream}
	if err := x.ClientStream.SendMsg(in); err != nil {
		return nil, err
	}
	if err := x.ClientStream.CloseSend(); err != nil {
		return nil, err
	}
	return x, nil
}

type Searcher_GetFavouritesClient interface {
	Recv() (*FavouritesPage, error)
	grpc.ClientStream
}

type searcherGetFavouritesClient struct {
	grpc.ClientStream
}

func (x *searcherGetFavouritesClient) Recv() (*FavouritesPage, error) {
	m := new(FavouritesPage)
	if err := x.ClientStream.RecvMsg(m); err != nil {
		return nil, err
	}
	return m, nil
}

// SearcherServer is the server API for Searcher service.
// All implementations must embed UnimplementedSearcherServer
// for forward compatibility
type SearcherServer interface {
	GetScore(context.Context, *GetScoreRequest) (*Score, error)
	GetScores(*GetScoresRequest, Searcher_GetScoresServer) error
	GetFavourites(*emptypb.Empty, Searcher_GetFavouritesServer) error
	mustEmbedUnimplementedSearcherServer()
}

// UnimplementedSearcherServer must be embedded to have forward compatible implementations.
type UnimplementedSearcherServer struct {
}

func (UnimplementedSearcherServer) GetScore(context.Context, *GetScoreRequest) (*Score, error) {
	return nil, status.Errorf(codes.Unimplemented, "method GetScore not implemented")
}
func (UnimplementedSearcherServer) GetScores(*GetScoresRequest, Searcher_GetScoresServer) error {
	return status.Errorf(codes.Unimplemented, "method GetScores not implemented")
}
func (UnimplementedSearcherServer) GetFavourites(*emptypb.Empty, Searcher_GetFavouritesServer) error {
	return status.Errorf(codes.Unimplemented, "method GetFavourites not implemented")
}
func (UnimplementedSearcherServer) mustEmbedUnimplementedSearcherServer() {}

// UnsafeSearcherServer may be embedded to opt out of forward compatibility for this service.
// Use of this interface is not recommended, as added methods to SearcherServer will
// result in compilation errors.
type UnsafeSearcherServer interface {
	mustEmbedUnimplementedSearcherServer()
}

func RegisterSearcherServer(s grpc.ServiceRegistrar, srv SearcherServer) {
	s.RegisterService(&Searcher_ServiceDesc, srv)
}

func _Searcher_GetScore_Handler(srv interface{}, ctx context.Context, dec func(interface{}) error, interceptor grpc.UnaryServerInterceptor) (interface{}, error) {
	in := new(GetScoreRequest)
	if err := dec(in); err != nil {
		return nil, err
	}
	if interceptor == nil {
		return srv.(SearcherServer).GetScore(ctx, in)
	}
	info := &grpc.UnaryServerInfo{
		Server:     srv,
		FullMethod: "/score.Searcher/GetScore",
	}
	handler := func(ctx context.Context, req interface{}) (interface{}, error) {
		return srv.(SearcherServer).GetScore(ctx, req.(*GetScoreRequest))
	}
	return interceptor(ctx, in, info, handler)
}

func _Searcher_GetScores_Handler(srv interface{}, stream grpc.ServerStream) error {
	m := new(GetScoresRequest)
	if err := stream.RecvMsg(m); err != nil {
		return err
	}
	return srv.(SearcherServer).GetScores(m, &searcherGetScoresServer{stream})
}

type Searcher_GetScoresServer interface {
	Send(*ScoresPage) error
	grpc.ServerStream
}

type searcherGetScoresServer struct {
	grpc.ServerStream
}

func (x *searcherGetScoresServer) Send(m *ScoresPage) error {
	return x.ServerStream.SendMsg(m)
}

func _Searcher_GetFavourites_Handler(srv interface{}, stream grpc.ServerStream) error {
	m := new(emptypb.Empty)
	if err := stream.RecvMsg(m); err != nil {
		return err
	}
	return srv.(SearcherServer).GetFavourites(m, &searcherGetFavouritesServer{stream})
}

type Searcher_GetFavouritesServer interface {
	Send(*FavouritesPage) error
	grpc.ServerStream
}

type searcherGetFavouritesServer struct {
	grpc.ServerStream
}

func (x *searcherGetFavouritesServer) Send(m *FavouritesPage) error {
	return x.ServerStream.SendMsg(m)
}

// Searcher_ServiceDesc is the grpc.ServiceDesc for Searcher service.
// It's only intended for direct use with grpc.RegisterService,
// and not to be introspected or modified (even as a copy)
var Searcher_ServiceDesc = grpc.ServiceDesc{
	ServiceName: "score.Searcher",
	HandlerType: (*SearcherServer)(nil),
	Methods: []grpc.MethodDesc{
		{
			MethodName: "GetScore",
			Handler:    _Searcher_GetScore_Handler,
		},
	},
	Streams: []grpc.StreamDesc{
		{
			StreamName:    "GetScores",
			Handler:       _Searcher_GetScores_Handler,
			ServerStreams: true,
		},
		{
			StreamName:    "GetFavourites",
			Handler:       _Searcher_GetFavourites_Handler,
			ServerStreams: true,
		},
	},
	Metadata: "searcher.proto",
}
