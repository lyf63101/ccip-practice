// Code generated by mockery v2.38.0. DO NOT EDIT.

package mocks

import (
	context "context"

	common "github.com/ethereum/go-ethereum/common"

	mock "github.com/stretchr/testify/mock"
)

// OnchainAllowlist is an autogenerated mock type for the OnchainAllowlist type
type OnchainAllowlist struct {
	mock.Mock
}

// Allow provides a mock function with given fields: _a0
func (_m *OnchainAllowlist) Allow(_a0 common.Address) bool {
	ret := _m.Called(_a0)

	if len(ret) == 0 {
		panic("no return value specified for Allow")
	}

	var r0 bool
	if rf, ok := ret.Get(0).(func(common.Address) bool); ok {
		r0 = rf(_a0)
	} else {
		r0 = ret.Get(0).(bool)
	}

	return r0
}

// Close provides a mock function with given fields:
func (_m *OnchainAllowlist) Close() error {
	ret := _m.Called()

	if len(ret) == 0 {
		panic("no return value specified for Close")
	}

	var r0 error
	if rf, ok := ret.Get(0).(func() error); ok {
		r0 = rf()
	} else {
		r0 = ret.Error(0)
	}

	return r0
}

// Start provides a mock function with given fields: _a0
func (_m *OnchainAllowlist) Start(_a0 context.Context) error {
	ret := _m.Called(_a0)

	if len(ret) == 0 {
		panic("no return value specified for Start")
	}

	var r0 error
	if rf, ok := ret.Get(0).(func(context.Context) error); ok {
		r0 = rf(_a0)
	} else {
		r0 = ret.Error(0)
	}

	return r0
}

// UpdateFromContract provides a mock function with given fields: ctx
func (_m *OnchainAllowlist) UpdateFromContract(ctx context.Context) error {
	ret := _m.Called(ctx)

	if len(ret) == 0 {
		panic("no return value specified for UpdateFromContract")
	}

	var r0 error
	if rf, ok := ret.Get(0).(func(context.Context) error); ok {
		r0 = rf(ctx)
	} else {
		r0 = ret.Error(0)
	}

	return r0
}

// NewOnchainAllowlist creates a new instance of OnchainAllowlist. It also registers a testing interface on the mock and a cleanup function to assert the mocks expectations.
// The first argument is typically a *testing.T value.
func NewOnchainAllowlist(t interface {
	mock.TestingT
	Cleanup(func())
}) *OnchainAllowlist {
	mock := &OnchainAllowlist{}
	mock.Mock.Test(t)

	t.Cleanup(func() { mock.AssertExpectations(t) })

	return mock
}
