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
)

// This is a compile-time assertion to ensure that this generated file
// is compatible with the grpc package it is being compiled against.
// Requires gRPC-Go v1.32.0 or later.
const _ = grpc.SupportPackageIsVersion7

// SearcherClient is the client API for Searcher service.
//
// For semantics around ctx use and closing/ending streaming RPCs, please refer to https://pkg.go.dev/google.golang.org/grpc/?tab=doc#ClientConn.NewStream.
type SearcherClient interface {
	SearchScores(ctx context.Context, in *SearchRequest, opts ...grpc.CallOption) (*SearchResponse, error)
}

type searcherClient struct {
	cc grpc.ClientConnInterface
}

func NewSearcherClient(cc grpc.ClientConnInterface) SearcherClient {
	return &searcherClient{cc}
}

func (c *searcherClient) SearchScores(ctx context.Context, in *SearchRequest, opts ...grpc.CallOption) (*SearchResponse, error) {
	out := new(SearchResponse)
	err := c.cc.Invoke(ctx, "/score.Searcher/SearchScores", in, out, opts...)
	if err != nil {
		return nil, err
	}
	return out, nil
}

// SearcherServer is the server API for Searcher service.
// All implementations must embed UnimplementedSearcherServer
// for forward compatibility
type SearcherServer interface {
	SearchScores(context.Context, *SearchRequest) (*SearchResponse, error)
	mustEmbedUnimplementedSearcherServer()
}

// UnimplementedSearcherServer must be embedded to have forward compatible implementations.
type UnimplementedSearcherServer struct {
}

func (UnimplementedSearcherServer) SearchScores(context.Context, *SearchRequest) (*SearchResponse, error) {
	return nil, status.Errorf(codes.Unimplemented, "method SearchScores not implemented")
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

func _Searcher_SearchScores_Handler(srv interface{}, ctx context.Context, dec func(interface{}) error, interceptor grpc.UnaryServerInterceptor) (interface{}, error) {
	in := new(SearchRequest)
	if err := dec(in); err != nil {
		return nil, err
	}
	if interceptor == nil {
		return srv.(SearcherServer).SearchScores(ctx, in)
	}
	info := &grpc.UnaryServerInfo{
		Server:     srv,
		FullMethod: "/score.Searcher/SearchScores",
	}
	handler := func(ctx context.Context, req interface{}) (interface{}, error) {
		return srv.(SearcherServer).SearchScores(ctx, req.(*SearchRequest))
	}
	return interceptor(ctx, in, info, handler)
}

// Searcher_ServiceDesc is the grpc.ServiceDesc for Searcher service.
// It's only intended for direct use with grpc.RegisterService,
// and not to be introspected or modified (even as a copy)
var Searcher_ServiceDesc = grpc.ServiceDesc{
	ServiceName: "score.Searcher",
	HandlerType: (*SearcherServer)(nil),
	Methods: []grpc.MethodDesc{
		{
			MethodName: "SearchScores",
			Handler:    _Searcher_SearchScores_Handler,
		},
	},
	Streams:  []grpc.StreamDesc{},
	Metadata: "searcher.proto",
}
